Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.taskboard.TaskBoardApp'
  'Rally.app.Context'
  'Rally.app.TimeboxScope'
  'Rally.data.Ranker'
]

describe 'Rally.apps.taskboard.TaskBoardApp', ->

  beforeEach ->
    @workProducts = @mom.getData 'userstory', count: 3
    @artifactStub = @ajax.whenQuerying('artifact').respondWith @workProducts
    @taskStub = @ajax.whenQuerying('task').respondWithCount 3
    @taskStateValues = ['Defined', 'In-Progress', 'Completed']
    @ajax.whenQueryingAllowedValues('task', 'State').respondWith @taskStateValues
    @ajax.whenQuerying('iteration').respondWithCount 3

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'taskboardapp'

  helpers
    createApp: (settings = {}, options = {}, context = {}) ->
      contextValues = Ext.merge
        project:
          _ref: Rally.environment.getContext().getProjectRef()
        workspace:
          WorkspaceConfiguration:
            DragDropRankingEnabled: true
        timebox: Ext.create Rally.test.mock.data.WsapiModelFactory.getIterationModel(),
          _ref: '/iteration/1'
          Name: 'Iteration 1'
          StartDate: '2013-01-01'
          EndDate: '2013-01-15'
      , context

      @app = Ext.create 'Rally.apps.taskboard.TaskBoardApp',
        context: Ext.create 'Rally.app.Context', initialValues: contextValues
        settings: settings
        renderTo: options.renderTo || 'testDiv'
        height: 400

      @waitForLoad()

    getPlugin: (xtype, cmp = @app.down('rallygridboard')) ->
      _.find cmp.plugins, (plugin) ->
        plugin.ptype == xtype

    waitForLoad: ->
      @once(condition: => @app.down 'rallygridboard').then =>
        @gridboard = @app.down 'rallygridboard'
        @waitForComponentReady @gridboard

  describe 'plugins', ->
    describe 'filtering', ->
      it 'should use rallygridboard custom filter control', ->
        @createApp().then =>
          plugin = @getPlugin('rallygridboardcustomfiltercontrol')
          expect(plugin).toBeDefined()
          expect(plugin.filterChildren).toBe false
          expect(plugin.filterControlConfig.stateful).toBe true
          expect(plugin.filterControlConfig.stateId).toBe @app.getContext().getScopedStateId('taskboard-custom-filter-button')
          expect(plugin.filterControlConfig.modelNames).toEqual ['Task']

          expect(plugin.showOwnerFilter).toBe true
          expect(plugin.ownerFilterControlConfig.stateful).toBe true
          expect(plugin.ownerFilterControlConfig.stateId).toBe @app.getContext().getScopedStateId('taskboard-owner-filter')

    describe 'field picker', ->
      it 'should use rallygridboard field picker', ->
        @createApp().then =>
          plugin = @getPlugin('rallygridboardfieldpicker')
          expect(plugin).toBeDefined()
          expect(plugin.headerPosition).toBe 'left'
          expect(plugin.modelNames).toEqual ['Task']
          expect(@app.down('rallycardboard').columnConfig.fields).toEqual ['Estimate', 'ToDo']
          expect(plugin.boardFieldBlackList).toContain 'State'
          expect(plugin.boardFieldBlackList).toContain 'TaskIndex'

  describe '#hideAcceptedWork', ->
    it 'has the correct default settings', ->
      @createApp().then =>
        expect(@app.getSetting('hideAcceptedWork')).toBe false

    it 'does not include an accepted work filter when setting off', ->
      @createApp(hideAcceptedWork: false).then =>
        expect(@artifactStub).not.toBeWsapiRequestWith
          filters: [
            { property: 'ScheduleState', operator: '<', value: 'Accepted' }
          ]
        expect(@taskStub).not.toBeWsapiRequestWith
          filters: [
            { property: 'WorkProduct.ScheduleState', operator: '<', value: 'Accepted' }
          ]

    it 'does include an accepted work filter when setting on', ->
      @createApp(hideAcceptedWork: true).then =>
        expect(@artifactStub).toBeWsapiRequestWith
          filters: [
            { property: 'ScheduleState', operator: '<', value: 'Accepted' }
          ]
        expect(@taskStub).toBeWsapiRequestWith
          filters: [
            { property: 'WorkProduct.ScheduleState', operator: '<', value: 'Accepted' }
          ]

  describe 'board config', ->
    it 'sets up columns by state', ->
      @createApp().then =>
        board = @app.down 'rallycardboard'
        expect(board.attribute).toBe 'State'
        expect(_.pluck board.getColumns(), 'value').toEqual @taskStateValues

    it 'uses task board header for each row', ->
      @createApp().then =>
        board = @app.down 'rallycardboard'
        expect(board.rowConfig.headerConfig.xtype).toEqual 'rallytaskboardrowheader'

    it 'includes explicit sorters', ->
      @createApp().then =>
        board = @app.down 'rallycardboard'
        sorters = board.rowConfig.sorters
        expect(sorters.length).toBe 2
        expect(sorters[0].property).toBe Rally.data.Ranker.RANK_FIELDS.DND
        expect(sorters[0].direction).toBe 'ASC'
        expect(sorters[1].property).toBe Rally.data.Ranker.RANK_FIELDS.TASK
        expect(sorters[1].direction).toBe 'ASC'

    it 'disables cross lane dnd', ->
      @createApp().then =>
        board = @app.down 'rallycardboard'
        expect(board.rowConfig.enableCrossRowDragging).toBe false

    it 'specifies a sortField so that the board can correctly re-order rows', ->
      @createApp().then =>
        board = @app.down 'rallycardboard'
        expect(board.rowConfig.sortField).toBe Rally.data.Ranker.RANK_FIELDS.DND

  describe 'timebox scoping', ->
    it 'includes the timebox scope filter', ->
      @createApp().then =>
        expect(@artifactStub).toBeWsapiRequestWith
          filters: [@app.getContext().getTimeboxScope().getQueryFilter()]
        expect(@taskStub).toBeWsapiRequestWith
          filters: [@app.getContext().getTimeboxScope().getQueryFilter()]

    it 'destroys the old board when the timebox scope changes', ->
      @createApp().then =>
        iteration = @mom.getRecord 'iteration'
        scope = Ext.create 'Rally.app.TimeboxScope',
          record: iteration
        destroySpy = @spy @gridboard, 'destroy'
        @app.onTimeboxScopeChange scope
        @waitForCallback destroySpy

    it 'adds a new board when the timebox scope changes', ->
      @createApp().then =>
        @artifactStub.reset()
        @taskStub.reset()
        iteration = @mom.getRecord 'iteration'
        scope = Ext.create 'Rally.app.TimeboxScope',
          record: iteration
        @app.onTimeboxScopeChange scope
        @waitForLoad().then =>
          expect(@artifactStub).toBeWsapiRequestWith filters: [scope.getQueryFilter()]
          expect(@taskStub).toBeWsapiRequestWith filters: [scope.getQueryFilter()]

    it 'removes the board when the timebox scope changes to unscheduled', ->
      @createApp().then =>
        scope = Ext.create 'Rally.app.TimeboxScope',
          type: 'iteration'
        @app.onTimeboxScopeChange scope
        expect(@app.down('rallygridboard')).toBeNull()

  describe 'gridboard config', ->
    it 'should disable store auto smarts around rank fields parameters', ->
      @createApp().then =>
        expect(@gridboard.storeConfig.enableRankFieldParameterAutoMapping).toBe false

    it 'should pass context', ->
      @createApp().then =>
        expect(@gridboard.getContext()).toBe @app.getContext()

    it 'should pass modelNames', ->
      @createApp().then =>
        expect(@gridboard.modelNames).toEqual ['Task']

  describe '#addNew', ->
    beforeEach ->
      @createApp().then =>
        @addNew = @app.down 'rallyaddnew'
        @addNewHelper = new Helpers.AddNewHelper this, '#testDiv'
        @addNewHelper.clickAddNew()

    it 'adds a workproduct field with the correct data', ->
      workProductCombo = @addNew.down '#workProduct'
      expect(workProductCombo).not.toBeNull()
      expect(_.invoke workProductCombo.store.getRange(), 'get', '_ref').toEqual _.pluck @workProducts, '_ref'
      expect(workProductCombo.editable).toBe true
      expect(workProductCombo.typeAhead).toBe true
      expect(workProductCombo.queryMode).toBe 'local'

    it 'specifies correct record types', ->
      expect(@addNew.recordTypes).toEqual ['Task', 'Defect', 'Defect Suite', 'Test Set', 'User Story']

    it 'shows the work product field when task is chosen', ->
      workProductCombo = @addNew.down '#workProduct'
      typeCombo = @addNew.down '#type'
      typeCombo.setValue 'Defect'
      typeCombo.setValue 'Task'
      expect(workProductCombo.isVisible()).toBe true

    it 'hides the work product field when something other than task is chosen', ->
      workProductCombo = @addNew.down '#workProduct'
      typeCombo = @addNew.down '#type'
      typeCombo.setValue 'Defect'
      expect(workProductCombo.isVisible()).toBe false

    it 'adds a row to the board when a non task is created', ->
      newStory = ObjectID: 555, _ref: '/hierarchicalrequirement/555'
      @ajax.whenCreating('userstory').respondWith newStory
      typeCombo = @addNew.down '#type'
      typeCombo.setValue 'User Story'
      @addNewHelper.sendKeysForNameField().then =>
        @addNewHelper.clickAdd().then =>
          rows = @gridboard.getGridOrBoard().getRows()
          expect(rows.length).toBe 2
          expect(_.last(rows).getRowValue()).toBe newStory._ref

    it 'adds an entry to the work product field when a non task is created', ->
      newStory = ObjectID: 555, _ref: '/hierarchicalrequirement/555'
      @ajax.whenCreating('userstory').respondWith newStory
      typeCombo = @addNew.down '#type'
      typeCombo.setValue 'User Story'
      @addNewHelper.sendKeysForNameField().then =>
        @addNewHelper.clickAdd().then =>
          workProductCombo = @addNew.down '#workProduct'
          records = workProductCombo.store.getRange()
          expect(records.length).toBe @workProducts.length + 1
          expect(_.last(records).get('_ref')).toBe newStory._ref

  describe 'Fixed Header', ->
    it 'should add the fixed header plugin', ->
      @createApp().then =>
        expect(@getPlugin('rallyfixedheadercardboard', @app.down('rallygridboard').getGridOrBoard())).toBeDefined()

    it 'should set the initial gridboard height to the app height', ->
      @createApp().then =>
        expect(@app.down('rallygridboard').getHeight()).toBe @app.getHeight()

    it 'should update the size of the gridboard when the app height change', ->
      @createApp().then =>
        @app.setSize 1000, 500
        expect(@app.down('rallygridboard').getHeight()).toBe 500

    describe 'without iteration scope', ->
      beforeEach ->
        @createApp {}, {}, {timebox: null}

      it 'should set the initial gridboard height to the app height', ->
        expect(@app.down('rallygridboard').getHeight()).toBe @app.getHeight() - @app.getHeader().getHeight()

      it 'should update the size of the gridboard when the app height change', ->
        @app.setSize 1000, 500
        expect(@app.down('rallygridboard').getHeight()).toBe 500 - @app.getHeader().getHeight()

Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.board.BoardApp',
]

describe 'Rally.apps.board.BoardApp', ->

  beforeEach ->
    @ajax.whenQuerying('userstory').respondWithCount 1,
      values: [ ScheduleState: 'In-Progress' ]
      createImmediateSubObjects: true

    @ajax.whenQueryingAllowedValues('hierarchicalrequirement', 'ScheduleState').respondWith ['Defined', 'In-Progress', 'Completed', 'Accepted']
    @ajax.whenQueryingAllowedValues('defect', 'State').respondWith ['Submitted', 'Open', 'Fixed', 'Closed']

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'boardapp'

  it 'has the correct default settings', ->
    @createApp().then =>
      expect(@app.getSetting('groupByField')).toBe 'ScheduleState'
      expect(@app.getSetting('type')).toBe 'HierarchicalRequirement'
      expect(@app.getSetting('order')).toBe 'Rank'
      expect(@app.getSetting('query')).toBe ''

  it 'shows the correct type on the board', ->
    @createApp(type: 'defect', groupByField: 'State').then =>
      expect(@_getBoard().getTypes().length).toBe 1
      expect(@_getBoard().getTypes()[0]).toBe 'defect'

  it 'groups by the correct attribute on the board', ->
    @createApp(type: 'defect', groupByField: 'State').then =>
      expect(@_getBoard().getAttribute()).toBe 'State'

  it 'passes the current context to the board', ->
    @createApp({}, context:
      project:
        _ref: '/project/2'
    ).then =>
      expect(@_getBoard().getContext().getProject()._ref).toBe '/project/2'

  it 'passes the filters to the board', ->
    query = '(Name contains foo)'
    @createApp(query: query).then =>
      expect(@_getGridBoard().storeConfig.filters.length).toBe 1
      expect(@_getGridBoard().storeConfig.filters[0].toString())
        .toBe Rally.data.QueryFilter.fromQueryString(query).toString()

  it 'scopes the board to the current timebox scope', ->
    @createApp({}, context:
      timebox: Ext.create 'Rally.app.TimeboxScope', record: @_createIterationRecord()
    ).then =>
      expect(@_getGridBoard().storeConfig.filters.length).toBe 1
      expect(@_getGridBoard().storeConfig.filters[0].toString())
        .toBe @app.getContext().getTimeboxScope().getQueryFilter().toString()

  it 'does not filter by timebox if model does not have that timebox', ->
    @ajax.whenQuerying('testcase').respondWithCount 5
    @ajax.whenQueryingAllowedValues('testcase', 'Priority').respondWith ['None', 'Useful', 'Important', 'Critical']
    @createApp({type: 'testcase', groupByField: 'Priority'}, context:
      timebox: Ext.create 'Rally.app.TimeboxScope', record: @_createIterationRecord()
    ).then =>
      expect(@_getGridBoard().storeConfig.filters.length).toBe 0

  it 'scopes the board to the current timebox scope and specified query filter', ->
    query = '(Name contains foo)'
    @createApp({query: query}, context:
        timebox: Ext.create 'Rally.app.TimeboxScope', record: @_createIterationRecord()
    ).then =>
      expect(@_getGridBoard().storeConfig.filters.length).toBe 2
      expect(@_getGridBoard().storeConfig.filters[0].toString())
        .toBe Rally.data.QueryFilter.fromQueryString(query).toString()
      expect(@_getGridBoard().storeConfig.filters[1].toString())
        .toBe @app.getContext().getTimeboxScope().getQueryFilter().toString()

  it 'refreshes the board when the timebox scope changes', ->
    newTimebox = @_createIterationRecord(
      _ref: '/iteration/2'
      Name: 'Iteration 2',
      StartDate: '2012-01-01',
      EndDate: '2012-01-15'
    )

    @createApp({}, context:
      timebox: Ext.create 'Rally.app.TimeboxScope', record: @_createIterationRecord()
    ).then =>
      boardDestroySpy = @spy @_getGridBoard(), 'destroy'
      Rally.environment.getMessageBus().publish(Rally.app.Message.timeboxScopeChange,
        Ext.create('Rally.app.TimeboxScope', record: newTimebox))

      @waitForCallback(boardDestroySpy).then =>
        expect(@_getGridBoard().storeConfig).toOnlyHaveFilterString @app.getContext().getTimeboxScope().getQueryFilter().toString()

  it 'returns settings fields with correct context', ->
    @createApp().then =>

      getFieldsSpy = @spy(Rally.apps.board.Settings, 'getFields')
      settingsFields = @app.getSettingsFields()

      expect(getFieldsSpy).toHaveBeenCalledOnce()
      expect(getFieldsSpy.getCall(0).returnValue).toBe settingsFields
      expect(getFieldsSpy.getCall(0).args[0]).toBe @app.getContext()

  it 'should include rows configuration with rowsField when showRows setting is true', ->
    @createApp(showRows: true, rowsField: 'Owner').then =>
      expect(@_getBoard().rowConfig.field).toBe 'Owner'
      expect(@_getBoard().rowConfig.sortDirection).toBe 'ASC'

  it 'should not include rows configuration when showRows setting is false', ->
    @createApp(showRows: false, rowsField: 'Owner').then =>
      expect(@_getBoard().rowConfig).toBeNull()

  it 'should include sorters from order setting', ->
    @createApp(order: 'Name').then =>
      sorters = @_getBoard().storeConfig.sorters
      expect(sorters.length).toBe 1
      expect(sorters[0].property).toBe @app.getSetting('order')

  it 'should set the initial gridboard height to the app height', ->
    @createApp().then =>
      expect(@app.down('rallygridboard').getHeight()).toBe @app.getHeight()

  describe 'plugins', ->

    describe 'filtering', ->
      it 'should use rallygridboard custom filter control', ->
        @createApp().then =>
          plugin = @_getPlugin('rallygridboardcustomfiltercontrol')
          expect(plugin).toBeDefined()
          expect(plugin.filterChildren).toBe false
          expect(plugin.filterControlConfig.stateful).toBe true
          expect(plugin.filterControlConfig.stateId).toBe @app.getContext().getScopedStateId('board-custom-filter-button')
          expect(plugin.filterControlConfig.modelNames).toEqual [@app.getSetting('type')]

          expect(plugin.showOwnerFilter).toBe true
          expect(plugin.ownerFilterControlConfig.stateful).toBe true
          expect(plugin.ownerFilterControlConfig.stateId).toBe @app.getContext().getScopedStateId('board-owner-filter')

    describe 'field picker', ->
      it 'should use rallygridboard field picker', ->
        @createApp(fields: 'Foo,Bar').then =>
          plugin = @_getPlugin('rallygridboardfieldpicker')
          expect(plugin).toBeDefined()
          expect(plugin.headerPosition).toBe 'left'
          expect(plugin.modelNames).toEqual [@app.getSetting('type')]
          expect(plugin.boardFieldDefaults).toEqual @app.getSetting('fields').split(',')

  helpers
    createApp: (settings = {}, options = {}) ->
      @app = Ext.create 'Rally.apps.board.BoardApp',
        context: @_createContext options.context
        settings: settings
        renderTo: options.renderTo || 'testDiv'
        height: 400

      @once(condition: => @_getBoard()).then =>
        @waitForComponentReady @_getBoard()

    _createContext: (context={}) ->
      Ext.create('Rally.app.Context',
        initialValues: Ext.apply(
          project:
            _ref: '/project/1'
            Name: 'Project 1'
          workspace:
            WorkspaceConfiguration:
              DragDropRankingEnabled: true
        , context)
      )

    _createIterationRecord: (data={}) ->
      IterationModel = Rally.test.mock.data.WsapiModelFactory.getIterationModel()
      Ext.create(IterationModel, Ext.apply(
        _ref: '/iteration/1',
        Name: 'Iteration 1',
        StartDate: '2013-01-01',
        EndDate: '2013-01-15'
      , data))

    _getGridBoard: ->
      @app.down('rallygridboard')

    _getBoard: ->
      @app.down('rallycardboard')

    _getPlugin: (xtype) ->
      _.find @_getGridBoard().plugins, (plugin) ->
        plugin.ptype == xtype
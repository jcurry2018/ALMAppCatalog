Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.iterationtrackingboard.IterationTrackingBoardApp'
  'Rally.ui.gridboard.GridBoard'
  'Rally.util.DateTime'
  'Rally.app.Context',
  'Rally.domain.Subscription'
]

describe 'Rally.apps.iterationtrackingboard.IterationTrackingBoardApp', ->

  helpers
    createApp: (config, stubStatsBannerHeight = true) ->
      if (stubStatsBannerHeight) then @stub(Rally.apps.iterationtrackingboard.StatsBanner::, 'getHeight').returns 0
      now = new Date(1384305300 * 1000);
      tomorrow = Rally.util.DateTime.add(now, 'day', 1)
      nextDay = Rally.util.DateTime.add(tomorrow, 'day', 1)
      dayAfter = Rally.util.DateTime.add(nextDay, 'day', 1)
      @iterationData = [
        {Name:'Iteration 1', StartDate: now, EndDate: tomorrow}
        {Name:'Iteration 2', StartDate: nextDay, EndDate: dayAfter}
      ]

      @iterationRecord = @mom.getRecord('iteration', values: @iterationData[0])
      scopeRecord = if Ext.isDefined(config?.iterationRecord) then config.iterationRecord else @iterationRecord

      @app = Ext.create('Rally.apps.iterationtrackingboard.IterationTrackingBoardApp', Ext.apply(
        context: Ext.create('Rally.app.Context',
          initialValues:
            timebox: Ext.create 'Rally.app.TimeboxScope', type: 'iteration', record: scopeRecord
            project:
              _ref: @projectRef
            workspace:
              WorkspaceConfiguration:
                DragDropRankingEnabled: true
                WorkDays: "Monday,Friday"
            subscription: Rally.environment.getContext().getSubscription()
        ),
        renderTo: 'testDiv'
        height: 400
      , config))

      @waitForComponentReady(@app)

    getIterationFilter: ->
      iteration = @iterationData[0]

      [
        { property: 'Iteration.Name', operator: '=', value: iteration.Name }
        { property: "Iteration.StartDate", operator: '=', value: Rally.util.DateTime.toIsoString(iteration.StartDate) }
        { property: "Iteration.EndDate", operator: '=', value: Rally.util.DateTime.toIsoString(iteration.EndDate) }
      ]

    stubRequests: ->
      @ajax.whenQueryingAllowedValues('userstory', 'ScheduleState').respondWith(["Defined", "In-Progress", "Completed", "Accepted"]);

      @ajax.whenQuerying('artifact').respondWith [{
        RevisionHistory:
          _ref: '/revisionhistory/1'
      }]

    toggleToBoard: ->
      @app.gridboard.setToggleState('board')

    toggleToGrid: ->
      @app.gridboard.setToggleState('grid')

    stubFeatureToggle: (toggles, value = true) ->
      stub = @stub(Rally.app.Context.prototype, 'isFeatureEnabled');
      stub.withArgs(toggle).returns(value) for toggle in toggles
      stub

  beforeEach ->
    @defaultToggleState = Rally.ui.gridboard.GridBoard.prototype.toggleState
    Rally.ui.gridboard.GridBoard.prototype.toggleState = 'board' # tests assume board is default view

    @ajax.whenReading('project').respondWith {
      TeamMembers: []
      Editors: []
    }

    @ajax.whenQuerying('iteration').respondWith([],
      schema:
        properties:
          EndDate:
            format:
              tzOffset: 0
    )

    @stubRequests()

    @tooltipHelper = new Helpers.TooltipHelper this

  afterEach ->
    @app?.destroy()
    Rally.ui.gridboard.GridBoard.prototype.toggleState = @defaultToggleState

  it 'should use anchor layout by default', ->
    @createApp().then =>
      expect(@app.layout.$className).toBe 'Ext.layout.container.Anchor'

  it 'should not render a header', ->
    try
      @createApp().then =>
        header = @app.down('container[cls=header]')
        expect(header == null).toBe true

  it 'resets view on scope change', ->
    @createApp().then =>
      removeSpy = @spy(@app, 'remove')

      newScope = Ext.create('Rally.app.TimeboxScope',
        record: @mom.getRecord('iteration', values: @iterationData[1])
      )

      @app.onTimeboxScopeChange newScope

      expect(removeSpy).toHaveBeenCalledTwice()
      expect(removeSpy).toHaveBeenCalledWith 'statsBanner'
      expect(removeSpy).toHaveBeenCalledWith 'gridBoard'

      expect(@app.down('#gridBoard')).toBeDefined()
      expect(@app.down('#statsBanner')).toBeDefined()

  it 'fires storecurrentpagereset on scope change', ->
    @createApp().then =>
      treeGrid = Ext.create 'Ext.Component'
      downStub = @stub(@app, 'down').withArgs('rallytreegrid').returns treeGrid
      downStub.withArgs('#statsBanner').returns(Ext.create('Ext.Component'))

      storeCurrentPageResetStub = @stub()
      @app.down('rallytreegrid').on 'storecurrentpagereset', storeCurrentPageResetStub

      newScope = Ext.create('Rally.app.TimeboxScope',
        record: @mom.getRecord('iteration', values: @iterationData[1])
      )

      @app.onTimeboxScopeChange newScope

      expect(storeCurrentPageResetStub).toHaveBeenCalledOnce()

  describe 'stats banner', ->
    it 'should add the stats banner by default', ->
      @createApp().then =>
        statsBanner = @app.down '#statsBanner'
        expect(statsBanner).not.toBeNull()
        expect(statsBanner.getContext()).toBe @app.getContext()

    it 'should not add the stats banner when the user sets it to not show', ->
      @stub(Rally.apps.iterationtrackingboard.IterationTrackingBoardApp::, 'getSetting').withArgs('showStatsBanner').returns(false)
      @createApp().then =>
        expect(@app.down('#statsBanner')).toBeNull()

    it 'should add the stats banner when the user sets it to show', ->
      @stub(Rally.apps.iterationtrackingboard.IterationTrackingBoardApp::, 'getSetting').withArgs('showStatsBanner').returns(true)
      @createApp().then =>
        expect(@app.down('#statsBanner')).not.toBeNull()

    it 'should not add the stats banner when includeStatsBanner is set to false', ->
      @createApp(includeStatsBanner: false).then =>
        expect(@app.down('#statsBanner')).toBeNull()

    it 'should resize the grid board when stats banner is toggled', ->
      @createApp().then =>
        statsBanner = @app.down '#statsBanner'
        setHeightSpy = @spy @app.down('rallygridboard'), 'setHeight'
        statsBanner.setHeight 40
        @waitForCallback(setHeightSpy)

  it 'fires contentupdated event after board load', ->
    contentUpdatedHandlerStub = @stub()
    @createApp(
      listeners:
        contentupdated: contentUpdatedHandlerStub
    ).then =>
      contentUpdatedHandlerStub.reset()
      @app.gridboard.fireEvent('load')

      expect(contentUpdatedHandlerStub).toHaveBeenCalledOnce()

  it 'should include PortfolioItem in columnConfig.additionalFetchFields', ->
    @createApp().then =>
      expect(@app.gridboard.getGridOrBoard().columnConfig.additionalFetchFields).toContain 'PortfolioItem'

  it 'should have a default card fields setting', ->
    @createApp().then =>
      expect(@app.down('rallygridboard').getGridOrBoard().columnConfig.fields).toEqual ['Parent', 'Tasks', 'Defects', 'Discussion', 'PlanEstimate', 'Iteration']

  it 'should have use the cardFields setting if available', ->
    @createApp(
      settings:
        cardFields: 'HelloKitty'
    ).then =>
      expect(@app.down('rallygridboard').getGridOrBoard().columnConfig.fields).toEqual ['HelloKitty']

  it 'should have the rowSettings field', ->
    @createApp().then =>
      expect(_.find(@app.getSettingsFields(), {xtype: 'rowsettingsfield'})).toBeDefined()

  it 'adds the rowConfig property to the boardConfig', ->
    @createApp(
      settings:
        showRows: true
    ).then =>
      expect(@app.gridboard.getGridOrBoard().config.rowConfig).toBeDefined()

  it 'adds the requiresModelSpecificFilters property to the boardConfig', ->
    @createApp().then =>
      expect(@app.gridboard.getGridOrBoard().columnConfig.requiresModelSpecificFilters).toBe false

  it 'should show the field picker in board mode', ->
    @createApp().then =>
      @toggleToBoard()
      expect(@app.down('#fieldpickerbtn').isVisible()).toBe true

  it 'should enable bulk edit', ->
    @createApp().then =>
      @toggleToGrid()
      expect(@app.down('#gridBoard').getGridOrBoard().enableBulkEdit).toBe true

  it 'should show a treegrid when treegrid toggled on', ->
    @createApp().then =>
      @toggleToGrid()
      expect(@app.down('rallytreegrid')).not.toBeNull()
      expect(@app.down('rallygrid')).toBeNull()

  describe 'iteration filtering', ->
    describe 'with a scope', ->
      it 'should filter the grid to the currently selected iteration', ->
        requestStub = @stubRequests()

        @createApp().then =>
          @toggleToGrid()

          expect(requestStub).toBeWsapiRequestWith filters: @getIterationFilter()

      it 'should filter the board to the currently selected iteration', ->
        requests = @stubRequests()

        @createApp().then =>
          @toggleToBoard()

          expect(request).toBeWsapiRequestWith(filters: @getIterationFilter()) for request in requests

    describe 'unscheduled', ->
      helpers
        createLeafStoriesOnlyFilter: ->
          storyTypeDefOid = Rally.test.mock.data.WsapiModelFactory.getModel('UserStory').typeDefOid
          Ext.create('Rally.data.wsapi.Filter',
            property: 'TypeDefOid'
            value: storyTypeDefOid
          ).and(Ext.create('Rally.data.wsapi.Filter',
            property: 'DirectChildrenCount'
            value: 0
          )).or(Ext.create('Rally.data.wsapi.Filter',
            property: 'TypeDefOid'
            operator: '!='
            value: storyTypeDefOid
          ))
        createUnassociatedDefectsOnlyFilter: ->
          defectTypeDefOid = Rally.test.mock.data.WsapiModelFactory.getModel('Defect').typeDefOid
          Ext.create('Rally.data.wsapi.Filter',
            property: 'TypeDefOid'
            value: defectTypeDefOid
          ).and(Ext.create('Rally.data.wsapi.Filter',
            property: 'Requirement.Iteration'
            operator: '!='
            value: null
          ).or(Ext.create('Rally.data.wsapi.Filter',
            property: 'Requirement'
            operator: '='
            value: null
          ))).or(Ext.create('Rally.data.wsapi.Filter',
            property: 'TypeDefOid'
            operator: '!='
            value: defectTypeDefOid
          ))

      describe 'stories', ->
        it 'should exclude epic stories from the grid', ->
          requestStub = @stubRequests()
          @createApp(iterationRecord: null).then =>
            @toggleToGrid()
            expect(requestStub).toBeWsapiRequestWith
              filters: [@createLeafStoriesOnlyFilter()]

        it 'should not attach leaf-stories-only filter if iteration is not null', ->
          requestStub = @stubRequests()
          @createApp().then =>
            @toggleToGrid()
            expect(requestStub).not.toBeWsapiRequestWith
              filters: [@createLeafStoriesOnlyFilter()]

      describe 'defects', ->
        it 'should exclude associated defects from the grid', ->
          requestStub = @stubRequests()
          @createApp(iterationRecord: null).then =>
            @toggleToGrid()
            expect(requestStub).toBeWsapiRequestWith
              filters: [@createUnassociatedDefectsOnlyFilter()]

        it 'should not attach unassociated-defects-only filter if iteration is not null', ->
          requestStub = @stubRequests()
          @createApp().then =>
            @toggleToGrid()
            expect(requestStub).not.toBeWsapiRequestWith
              filters: [@createUnassociatedDefectsOnlyFilter()]


  describe 'tree grid config', ->

    it 'returns the columns with the FormattedID removed', ->
      @createApp().then =>
        @toggleToGrid()
        expect(@app.down('#gridBoard').getGridOrBoard().initialConfig.columnCfgs).toEqual ['Name', 'ScheduleState', 'Blocked', 'PlanEstimate', 'Tasks', 'TaskEstimateTotal', 'TaskRemainingTotal', 'Owner', 'Defects', 'Discussion']

    it 'enables the summary row on the treegrid when the toggle is on', ->
      @createApp().then =>
        @toggleToGrid()
        expect(@app.down('#gridBoard').getGridOrBoard().summaryColumns.length).toBe 4

    it 'should include test sets', ->
      @createApp().then =>
        @toggleToGrid()
        expect(@app.down('rallytreegrid').getStore().parentTypes).toContain 'testset'

    it 'should include dataContext', ->
      buildSpy = @spy(Rally.data.wsapi.TreeStoreBuilder::, 'build')
      @createApp().then (app) ->
        expect(buildSpy.getCall(0).args[0].context).toEqual app.getContext().getDataContext()

    describe 'enableInlineAdd config', ->
      beforeEach ->
        @stubFeatureToggle(['F6038_ENABLE_INLINE_ADD'])

      it 'should fetch PlanEstimate, Release and Iteration', ->
        @createApp().then =>
          @toggleToGrid()
          store = @app.down('rallytreegrid').getStore()
          expect(store.fetch).toContain 'PlanEstimate'
          expect(store.fetch).toContain 'Release'
          expect(store.fetch).toContain 'Iteration'

      it 'should pass in enableAddPlusNewChildStories to inlineAddRowExpander plugin', ->
        @createApp().then =>
          @toggleToGrid()
          inlineAddRowExpander = _.find(@app.down('rallytreegrid').plugins, {'ptype': 'rallyinlineaddrowexpander'})
          expect(inlineAddRowExpander.enableAddPlusNewChildStories).toBe false

    describe 'with S77241_SHOW_EXPAND_ALL_IN_GRID_HEADER toggle off', ->
      beforeEach ->
        @stubFeatureToggle ['S77241_SHOW_EXPAND_ALL_IN_GRID_HEADER'], false

      it 'adds the gridboard expandall plugin', ->
        @createApp().then =>
          @toggleToGrid()
          expect(@app.down('#gridBoard').initialConfig.plugins).toContain 'rallygridboardexpandall'

      it 'sets the expandAllInColumnHeaderEnabled to false', ->
        @createApp().then =>
          @toggleToGrid()
          expect(@app.down('#gridBoard').getGridOrBoard().initialConfig.expandAllInColumnHeaderEnabled).toBe false

    describe 'with S77241_SHOW_EXPAND_ALL_IN_GRID_HEADER toggle on', ->
      beforeEach ->
        @stubFeatureToggle ['S77241_SHOW_EXPAND_ALL_IN_GRID_HEADER'], true

      it 'does not add the gridboard expandall plugin', ->
        @createApp().then =>
          @toggleToGrid()
          expect(@app.down('#gridBoard').initialConfig.plugins).not.toContain 'rallygridboardexpandall'

      it 'sets the expandAllInColumnHeaderEnabled to true', ->
        @createApp().then =>
          @toggleToGrid()
          expect(@app.down('#gridBoard').getGridOrBoard().initialConfig.expandAllInColumnHeaderEnabled).toBe true

  describe 'toggle grid/board cls to ensure overflow-y gets set for fixed header plugin', ->
    it 'should add board-toggled class to app on initial load in board view', ->
      @stub(Rally.ui.gridboard.GridBoard::, 'toggleState', 'board')
      @createApp().then =>
        expect(@app.getEl().dom.className).toContain 'board-toggled'

    it 'should add board-toggled class to app when toggled to board view', ->
      @createApp().then =>
        @toggleToBoard()
        expect(@app.getEl().dom.className).toContain 'board-toggled'

    it 'should add grid-toggled class to app when toggled to grid view', ->
      @createApp().then =>
        @toggleToGrid()
        expect(@app.getEl().dom.className).toContain 'grid-toggled'

  describe "summary units", ->
    helpers
      createAppWithWorkspaceConfiguration: (workspaceConfig) ->
        context = Ext.create('Rally.app.Context',
          initialValues:
            timebox: Ext.create 'Rally.app.TimeboxScope', record: @mom.getRecord('iteration')
            project:
              _ref: @projectRef
            workspace:
              WorkspaceConfiguration: _.defaults(WorkDays: "Monday,Friday", workspaceConfig)

        )
        @createApp({ context }).then =>
          @toggleToGrid()

      getSummaryColumns: ->
        @app.down('rallytreegrid').summaryColumns

    it "should specify the summary columns", ->
      @createAppWithWorkspaceConfiguration(TaskUnitName: 'dogecoins').then =>
        summaryColumns = @getSummaryColumns()
        expect(summaryColumns.length).toBe(4)
        expect(summaryColumns[0].field).toBe('PlanEstimate')
        expect(summaryColumns[0].type).toBe('sum')
        expect(summaryColumns[1].field).toBe('TaskEstimateTotal')
        expect(summaryColumns[1].type).toBe('sum')
        expect(summaryColumns[2].field).toBe('TaskRemainingTotal')
        expect(summaryColumns[2].type).toBe('sum')
        expect(summaryColumns[3].field).toBe('TaskActualTotal')
        expect(summaryColumns[3].type).toBe('sum')

    it "should use the workspace's task unit name", ->
      @createAppWithWorkspaceConfiguration(TaskUnitName: 'dogecoins').then =>
        summaryColumns = @getSummaryColumns()
        expect(summaryColumns[1].units).toBe('dogecoins')
        expect(summaryColumns[2].units).toBe('dogecoins')

    it "should use the workspace's iteration estimate unit name", ->
      workspaceConfig =
        IterationEstimateUnitName: 'shebas'
        ReleaseEstimateUnitName: 'kitties'

      @createAppWithWorkspaceConfiguration(workspaceConfig).then =>
        summaryColumns = @getSummaryColumns()
        expect(summaryColumns[0].units).toBe('shebas')

  describe 'sizing', ->
    it 'should set an initial gridboard height', ->
      @createApp().then =>
        expect(@app.down('rallygridboard').getHeight()).toBe @app._getAvailableGridBoardHeight()

    it 'should factor in header height and stats banner height when determining gridboard height', ->
      @createApp({}, false).then =>
        statsBanner = @app.down('#statsBanner')
        gridBoard = @app.down('rallygridboard')

        header = @app.add({
          xtype: 'container',
          cls: 'header',
          height: 20
        });

        setHeightSpy = @spy gridBoard, 'setHeight'

        @app.setHeight(500);

        @waitForCallback(setHeightSpy).then =>
          expect(gridBoard.getHeight()).toBe(@app.getHeight() - statsBanner.getHeight() - header.getHeight())

    it 'should update the grid or board height', ->
      @createApp().then =>
        gridBoard = @app.down 'rallygridboard'
        setHeightSpy = @spy gridBoard, 'setHeight'
        currentHeight = gridBoard.getHeight()
        @app.setHeight @app.getHeight() + 10
        @waitForCallback(setHeightSpy).then =>
          expect(gridBoard.getHeight()).toBe currentHeight + 10

  describe 'custom filter popover', ->
    beforeEach ->
      @featureEnabledStub = @stub(Rally.app.Context.prototype, 'isFeatureEnabled')

    it 'should add common storeConfig to gridboard', ->
      @createApp().then =>
        gridBoard = @app.down 'rallygridboard'
        expect(gridBoard.storeConfig.filters.length).toBe 1
        expect(gridBoard.storeConfig.filters[0].toString()).toBe @app.getContext().getTimeboxScope().getQueryFilter().toString()

    it 'should use rallygridboard custom filter control', ->
      @createApp().then =>
        gridBoard = @app.down 'rallygridboard'
        plugin = _.find gridBoard.plugins, (plugin) ->
          plugin.ptype == 'rallygridboardcustomfiltercontrol'
        expect(plugin).toBeDefined()
        expect(plugin.filterControlConfig.stateful).toBe true
        expect(plugin.filterControlConfig.stateId).toBe @app.getContext().getScopedStateId('iteration-tracking-custom-filter-button')

        expect(plugin.showOwnerFilter).toBe true
        expect(plugin.ownerFilterControlConfig.stateful).toBe true
        expect(plugin.ownerFilterControlConfig.stateId).toBe @app.getContext().getScopedStateId('iteration-tracking-owner-filter')

    it 'should include the Milestones field in the available Fields when the toggle is enabled', ->
      @stub(Rally.app.Context.prototype, '_isMilestoneEnabled').returns true
      @createApp().then =>
        filterPlugin = _.find(@app.gridboard.plugins, ptype: 'rallygridboardcustomfiltercontrol')
        expect(_.contains(filterPlugin.filterControlConfig.whiteListFields, 'Milestones')).toBe true

    it 'should not include the Milestones field in the available Fields when the toggle is not enabled', ->
      @stub(Rally.app.Context.prototype, '_isMilestoneEnabled').returns false
      @createApp().then =>
        filterPlugin = _.find(@app.gridboard.plugins, ptype: 'rallygridboardcustomfiltercontrol')
        expect(_.contains(filterPlugin.filterControlConfig.whiteListFields, 'Milestones')).toBe false

    describe 'Expand All', ->

      it 'should configure plugin', ->
        @createApp().then =>
          expect(_.find(@app.gridboard.plugins, ptype: 'rallygridboardexpandall')).toBeTruthy()

      describe 'in IE', ->
        beforeEach ->
          @_isIE = Ext.isIE
          Ext.isIE = true

        afterEach ->
          Ext.isIE = @_isIE

        it 'should not configure plugin for IE', ->
          @createApp().then =>
            expect(_.find(@app.gridboard.plugins, {ptype: 'rallygridboardexpandall'})).toBeFalsy()

  describe 'grid configurations', ->
    it 'should create a grid store with the correct page size', ->
      @createApp().then =>
        @toggleToGrid()

        expect(@app.gridboard.getGridOrBoard().store.pageSize).toEqual 25
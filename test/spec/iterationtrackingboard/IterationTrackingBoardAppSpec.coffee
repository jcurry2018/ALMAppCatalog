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
    createApp: (config)->
      now = new Date(1384305300 * 1000);
      tomorrow = Rally.util.DateTime.add(now, 'day', 1)
      nextDay = Rally.util.DateTime.add(tomorrow, 'day', 1)
      dayAfter = Rally.util.DateTime.add(nextDay, 'day', 1)
      @iterationData = [
        {Name:'Iteration 1', _ref:'/iteration/0', StartDate: now, EndDate: tomorrow}
        {Name:'Iteration 2', _ref:'/iteration/2', StartDate: nextDay, EndDate: dayAfter}
      ]

      @IterationModel = Rally.test.mock.data.WsapiModelFactory.getIterationModel()
      @iterationRecord = new @IterationModel @iterationData[0]

      @app = Ext.create('Rally.apps.iterationtrackingboard.IterationTrackingBoardApp', Ext.apply(
        context: Ext.create('Rally.app.Context',
          initialValues:
            timebox: Ext.create 'Rally.app.TimeboxScope', record: @iterationRecord
            project:
              _ref: @projectRef
            workspace:
              WorkspaceConfiguration:
                DragDropRankingEnabled: true
        ),
        renderTo: 'testDiv'
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
        RevisionHistory: {
          _ref: '/revisionhistory/1'
        }
      }]

    toggleToBoard: ->
      @app.gridboard.setToggleState('board')

    toggleToGrid: ->
      @app.gridboard.setToggleState('grid')

    stubFeatureToggle: (toggles) ->
      stub = @stub(Rally.app.Context.prototype, 'isFeatureEnabled');
      stub.withArgs(toggle).returns(true) for toggle in toggles
      stub

  beforeEach ->
    @ajax.whenReading('project').respondWith {
      TeamMembers: []
      Editors: []
    }

    @stubRequests()

    @tooltipHelper = new Helpers.TooltipHelper this

  afterEach ->
    @app?.destroy()

  it 'resets view on scope change', ->
    @createApp().then =>
      removeStub = @stub(@app, 'remove')

      newScope = Ext.create('Rally.app.TimeboxScope',
        record: new @IterationModel @iterationData[1]
      )

      @app.onTimeboxScopeChange newScope

      @waitForCallback(removeStub).then =>
        expect(removeStub).toHaveBeenCalledOnce()
        expect(removeStub).toHaveBeenCalledWith 'gridBoard'

        expect(@app.down('#gridBoard')).toBeDefined()

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
      expect(@app.down('rallygridboard').getGridOrBoard().columnConfig.fields).toEqual ['Parent', 'Tasks', 'Defects', 'Discussion', 'PlanEstimate']

  it 'should have use the cardFields setting if available', ->
    @createApp(
      settings:
        cardFields: 'HelloKitty'
    ).then =>
      expect(@app.down('rallygridboard').getGridOrBoard().columnConfig.fields).toEqual ['HelloKitty']

  it 'should show the field picker in board mode', ->
    @createApp().then =>
      @toggleToBoard()
      expect(@app.down('#fieldpickerbtn').isVisible()).toBe true

  it 'should enable bulk edit when toggled on', ->
    @stubFeatureToggle ['BETA_TRACKING_EXPERIENCE']
    @createApp().then =>
      @toggleToGrid()
      expect(@app.down('#gridBoard').getGridOrBoard().enableBulkEdit).toBe true

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

  it 'should show a treegrid when treegrid toggled on', ->
    @createApp().then =>
      @toggleToGrid()
      expect(@app.down('rallytreegrid')).not.toBeNull()
      expect(@app.down('rallygrid')).toBeNull()

  describe '#_getGridColumns', ->
    helpers
      _getDefaultCols: ->
        ['FormattedID', 'Name', 'ScheduleState', 'Blocked', 'PlanEstimate', 'TaskStatus', 'TaskEstimateTotal', 'TaskRemainingTotal', 'Owner', 'DefectStatus', 'Discussion']

    it 'returns the default columns with the FormattedID removed when given no input', ->
      @createApp().then =>
        cols = @app._getGridColumns()
        expectedColumns = _.remove(@_getDefaultCols(), (col) ->
          col != 'FormattedID'
        )

        expect(cols).toEqual expectedColumns

    it 'returns the input columns with the FormattedID removed', ->
      @createApp().then =>
        cols = @app._getGridColumns(['used1', 'used2', 'FormattedID'])

        expect(cols).toEqual ['used1', 'used2']

    it 'enables the summary row on the treegrid when the toggle is on', ->
      @createApp().then =>
        @toggleToGrid()
        expect(@app.down('#gridBoard').getGridOrBoard().showSummary).toBe true

  describe 'with the TREE_GRID_COLUMN_FILTERING toggle on', ->
    beforeEach ->
      @stubFeatureToggle ['TREE_GRID_COLUMN_FILTERING']

    it 'shows column menu trigger on hover for filterable column', ->
      @createApp().then =>
        @toggleToGrid()
        nameColumnHeaderSelector = '.btid-grid-header-name'
        @mouseOver(css: nameColumnHeaderSelector).then =>
          expect(@app.getEl().down("#{nameColumnHeaderSelector} .#{Ext.baseCSSPrefix}column-header-trigger").isVisible()).toBe true

    it 'has filter menu item for filterable column', ->
      @createApp().then =>
        @toggleToGrid()
        formattedIdColumnHeaderSelector = ".#{Ext.baseCSSPrefix}column-header:nth-child(3)"
        @mouseOver(css: formattedIdColumnHeaderSelector).then =>
          @click(css: "#{formattedIdColumnHeaderSelector} .#{Ext.baseCSSPrefix}column-header-trigger").then =>
            expect(Ext.getBody().down('.rally-grid-column-menu .filters-label')).not.toBeNull

  describe 'with the TREE_GRID_COLUMN_FILTERING toggle off', ->
    it 'does not show column menu trigger on hover for filterable column', ->
      @createApp().then =>
        @toggleToGrid()
        nameColumnHeaderSelector = '.btid-grid-header-name'
        @mouseOver(css: nameColumnHeaderSelector).then =>
          expect(@app.getEl().down("#{nameColumnHeaderSelector} .#{Ext.baseCSSPrefix}column-header-trigger")).toBeNull

  describe 'tree grid model types', ->
    it 'should include test sets', ->
      @createApp().then =>
        @toggleToGrid()
        expect(@app.down('rallytreegrid').getStore().parentTypes).toContain 'testset'

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
              WorkspaceConfiguration: workspaceConfig

        )
        @createApp({ context }).then =>
          @toggleToGrid()

      getSummaryColumns: ->
        @app.down('rallytreegrid').summaryColumns

    it "should specify the summary columns", ->
      @createAppWithWorkspaceConfiguration(TaskUnitName: 'dogecoins').then =>
        summaryColumns = @getSummaryColumns()
        expect(summaryColumns.length).toBe(3)
        expect(summaryColumns[0].field).toBe('PlanEstimate')
        expect(summaryColumns[0].type).toBe('sum')
        expect(summaryColumns[1].field).toBe('TaskEstimateTotal')
        expect(summaryColumns[1].type).toBe('sum')
        expect(summaryColumns[2].field).toBe('TaskRemainingTotal')
        expect(summaryColumns[2].type).toBe('sum')

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

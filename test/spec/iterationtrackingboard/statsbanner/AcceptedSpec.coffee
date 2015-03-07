Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.util.DateTime',
  'Rally.util.Colors'
]

describe 'Rally.apps.iterationtrackingboard.statsbanner.Accepted', ->

  helpers
    createPane: (config={}) ->
      @store = Ext.create 'Ext.data.Store',
        model: Rally.test.mock.data.WsapiModelFactory.getModel 'userstory'
      @pane = Ext.create 'Rally.apps.iterationtrackingboard.statsbanner.Accepted', _.defaults config,
        renderTo: 'testDiv'
        store: @store
        context:
          getWorkspace: -> Rally.environment.getContext().getWorkspace()
          getProject: -> Rally.environment.getContext().getProject()
          getTimeboxScope: =>
            config.scope || Ext.create 'Rally.app.TimeboxScope', record: @mom.getRecord 'iteration'

    refreshPane: (config={}, records) ->
      @createPane config
      @spy @pane, 'refreshChart'
      @store.add records || @mom.getRecord 'userstory'
      @waitForCallback @pane.refreshChart

    createAndWaitForUpdate: (config={}, records) ->
      @createPane config
      updateSpy = @spy @pane, 'update'
      @store.add records || @mom.getRecord 'userstory'
      @waitForCallback(updateSpy)

  beforeEach ->
    @ajax.whenQuerying('iteration').respondWith [],
      schema:
        properties:
          EndDate:
            format:
              tzOffset: 300

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'statsbanneraccepted'

  describe 'should calculate renderData correctly', ->
    it 'for iteration unit', ->
      @createAndWaitForUpdate().then (updateSpy) ->
        unit = updateSpy.getCall(0).args[0].unit
        expect(unit).toBe Rally.environment.getContext().getWorkspace().WorkspaceConfiguration.IterationEstimateUnitName

    it 'for release unit', ->
      @createAndWaitForUpdate(
        scope: Ext.create 'Rally.app.TimeboxScope', record: @mom.getRecord 'release'
      ).then (updateSpy) ->
        unit = updateSpy.getCall(0).args[0].unit
        expect(unit).toBe Rally.environment.getContext().getWorkspace().WorkspaceConfiguration.ReleaseEstimateUnitName

    describe 'should calculate percentage correctly', ->
      it 'for zero accepted and zero total', ->
        record = @mom.getRecord 'userstory',
          values:
            PlanEstimate: 0
        @createAndWaitForUpdate({}, record).then (updateSpy) =>
          expect(updateSpy.getCall(0).args[0].percentage).toBe 0
          expect(@pane.getEl().down('.metric-chart-text').dom.innerHTML).toContain '0'
          expect(@pane.getEl().down('.metric-subtext').dom.innerHTML).toContain '0 of 0 Points'

      it 'for typical accepted and total', ->
        record = @mom.getRecord 'userstory',
          values:
            PlanEstimate: 5
            ScheduleState: 'Accepted'
        @createAndWaitForUpdate({}, record).then (updateSpy) =>
          expect(updateSpy.getCall(0).args[0].percentage).toBe 100
          expect(@pane.getEl().down('.metric-chart-text').dom.innerHTML).toContain '100'
          expect(@pane.getEl().down('.metric-subtext').dom.innerHTML).toContain '5 of 5 Points'

      it 'for decimals in accepted and total', ->
        record = @mom.getRecords 'userstory',
          values: [
            {PlanEstimate: .1, ScheduleState: 'Accepted'}
            {PlanEstimate: .1, ScheduleState: 'Accepted'}
            {PlanEstimate: .1, ScheduleState: 'Accepted'}
          ]
          count: 3
        @createAndWaitForUpdate({}, record).then (updateSpy) =>
          expect(updateSpy.getCall(0).args[0].percentage).toBe 100
          expect(@pane.getEl().down('.metric-chart-text').dom.innerHTML).toContain '100'
          expect(@pane.getEl().down('.metric-subtext').dom.innerHTML).toContain '0.3 of 0.3 Points'

  describe 'should calculate chartConfig correctly', ->
    it 'for 100% accepted', ->
      record = @mom.getRecord 'userstory',
        values:
          PlanEstimate: 5
          ScheduleState: 'Accepted'
      @refreshPane({}, record).then =>
        data = @pane.refreshChart.getCall(0).args[0].chartData.series[0].data[0]
        expect(data.y).toBe 100
        expect(data.color).toBe Rally.util.Colors.lime

    it 'for 0 days remaining', ->
      record = @mom.getRecord 'userstory',
        values:
          PlanEstimate: 5
          ScheduleState: 'Defined'
      scope = Ext.create 'Rally.app.TimeboxScope',
        record: @mom.getRecord 'iteration',
          values:
            EndDate: '2013-01-01'
      @refreshPane(scope: scope, record).then =>
        data = @pane.refreshChart.getCall(0).args[0].chartData.series[0].data[0]
        expect(data.y).toBe 0
        expect(data.color).toBe Rally.util.Colors.blue

    it 'active iteration, not 100% accepted', ->
      record = @mom.getRecord 'userstory',
        values:
          PlanEstimate: 5
          ScheduleState: 'Defined'
      scope = Ext.create 'Rally.app.TimeboxScope',
        record: @mom.getRecord 'iteration',
          values:
            StartDate: '2014-01-01'
            EndDate: '2099-05-01'

      @refreshPane(scope: scope, record).then =>
        data = @pane.refreshChart.getCall(0).args[0].chartData.series[0].data[0]
        expect(data.y).toBe 0
        expect(data.color).toBe Rally.util.Colors.cyan

    it 'should reset accepted count on datachange', ->
      @createPane()
      @stub(@pane.data, 'accepted', 5)

      @spy @pane, 'refreshChart'
      @store.add @mom.getRecord 'userstory'
      @waitForCallback(@pane.refreshChart).then =>
        expect(@pane.getEl().down('.stat-metric').dom.innerHTML).toContain '0'
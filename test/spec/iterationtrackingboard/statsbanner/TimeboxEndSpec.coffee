Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.util.Colors'
]

describe 'Rally.apps.iterationtrackingboard.statsbanner.TimeboxEnd', ->

  helpers
    createPane: (config={}) ->
      @store = Ext.create 'Ext.data.Store',
        model: Rally.test.mock.data.WsapiModelFactory.getModel 'userstory'
      @pane = Ext.create 'Rally.apps.iterationtrackingboard.statsbanner.TimeboxEnd', _.defaults config,
        renderTo: 'testDiv'
        store: @store
        context:
          getWorkspace: ->
            workspace = Rally.environment.getContext().getWorkspace()
            workspace.WorkspaceConfiguration.WorkDays = 'Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday'
            workspace
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
    Rally.test.destroyComponentsOfQuery 'statsbannertimeboxend'

  describe 'should calculate renderData correctly', ->
    it 'for type', ->
      @createAndWaitForUpdate().then (updateSpy) =>
        type = updateSpy.getCall(0).args[0].type
        expect(type).toBe 'Iteration'
        expect(@pane.getEl().down('.stat-title').dom.innerHTML).toContain 'Iteration'

    it 'for remaining', ->
      @createAndWaitForUpdate().then (updateSpy) =>
        remaining = updateSpy.getCall(0).args[0].remaining
        expect(@pane.getEl().down('.metric-chart-text').dom.innerHTML).toContain remaining

    it 'for workdays', ->
      @createAndWaitForUpdate().then (updateSpy) =>
        workdays = updateSpy.getCall(0).args[0].workdays
        expect(@pane.getEl().down('.metric-subtext').dom.innerHTML).toContain workdays

  describe 'should calculate chartConfig correctly', ->
    it 'for no total', ->
      record = @mom.getRecord 'userstory',
        values:
          PlanEstimate: 0
          ScheduleState: 'Accepted'
      @refreshPane({}, record).then =>
        data = @pane.refreshChart.getCall(0).args[0].chartData.series[0].data[0]
        expect(data.y).toBe 100
        expect(data.color).toBe Rally.util.Colors.grey1

    describe 'for no time left', ->
      it 'and 100% accepted', ->
        record = @mom.getRecord 'userstory',
          values:
            PlanEstimate: 5
            ScheduleState: 'Accepted'
        scope = Ext.create 'Rally.app.TimeboxScope',
          record: @mom.getRecord 'iteration',
            values:
              EndDate: '2013-01-01'
        @refreshPane(scope: scope, record).then =>
          data = @pane.refreshChart.getCall(0).args[0].chartData.series[0].data[0]
          expect(data.y).toBe 100
          expect(data.color).toBe Rally.util.Colors.lime

      it 'and not 100% accepted', ->
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
          expect(data.y).toBe 100
          expect(data.color).toBe Rally.util.Colors.blue

    it 'for less than 25% time left', ->
      record = @mom.getRecord 'userstory',
        values:
          PlanEstimate: 5
          ScheduleState: 'Accepted'
      now = new Date()
      scope = Ext.create 'Rally.app.TimeboxScope',
        record: @mom.getRecord 'iteration',
          values:
            StartDate: Rally.util.DateTime.toIsoString Ext.Date.add now, Ext.Date.DAY, -6
            EndDate: Rally.util.DateTime.toIsoString Ext.Date.add now, Ext.Date.DAY, 1
      @refreshPane(scope: scope, record).then =>
        data = @pane.refreshChart.getCall(0).args[0].chartData.series[0].data[0]
        expect(data.y).toBe 75
        expect(data.color).toBe Rally.util.Colors.blue

    it 'should reset accepted count on datachange', ->
      @createPane remaining: 5

      @spy @pane, 'refreshChart'
      @store.add @mom.getRecord 'userstory'
      @waitForCallback(@pane.refreshChart).then =>
        expect(@pane.getEl().down('.stat-metric').dom.innerHTML).toContain '0'
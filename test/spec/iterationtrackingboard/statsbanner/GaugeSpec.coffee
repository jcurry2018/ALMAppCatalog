Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.util.Timebox',
  'Rally.apps.iterationtrackingboard.statsbanner.Gauge',
  'Rally.util.Colors'
]

describe 'Rally.apps.iterationtrackingboard.statsbanner.Gauge', ->

  helpers
    createGauge: (config={})->
      @store = Ext.create 'Ext.data.Store',
        model: Rally.test.mock.data.WsapiModelFactory.getModel 'userstory'
      @gauge = Ext.create 'Rally.apps.iterationtrackingboard.statsbanner.Gauge', _.defaults config,
        renderTo: 'testDiv'
        chart:
          doLayout: @stub()
          updateLayout: @stub()
          destroy: @stub()
        store: @store
        context:
          getWorkspace: -> Rally.environment.getContext().getWorkspace()
          getProject: -> Rally.environment.getContext().getProject()
          getTimeboxScope: =>
            config.scope || Ext.create 'Rally.app.TimeboxScope', record: @mom.getRecord 'iteration'

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'statsbannergauge'

  it 'should on render add empty chart when there is no timebox', ->
    @createGauge scope: Ext.create 'Rally.app.TimeboxScope', type: 'iteration'

    chartSeriesData = Ext.ComponentQuery.query('rallychart')[0].chartData.series[0].data[0]
    expect(chartSeriesData.y).toBe 100
    expect(chartSeriesData.color).toBe Rally.util.Colors.grey1

  it 'should call onDataChange when store is updated', ->
    onDataChanged = @spy Rally.apps.iterationtrackingboard.statsbanner.Gauge::, 'onDataChanged'
    @createGauge()
    @store.add @mom.getRecord 'userstory'

    expect(onDataChanged.callCount).toBe 1

  it 'should on destroy clean up chart', ->
    @createGauge scope: Ext.create 'Rally.app.TimeboxScope', type: 'iteration'
    expect(Ext.ComponentQuery.query('rallychart').length).toBe 1
    @gauge.destroy()
    expect(Ext.ComponentQuery.query('rallychart').length).toBe 0

  it 'should update chart layout when gauge is resized', ->
    @createGauge scope: Ext.create 'Rally.app.TimeboxScope', type: 'iteration'
    chart = Ext.ComponentQuery.query('rallychart')[0]
    @spy chart, 'updateLayout'
    @gauge.onResize 100, 100
    expect(chart.updateLayout.callCount).toBe 1

  it 'should not update chart layout if banner is collapsed', ->
    @createGauge scope: Ext.create 'Rally.app.TimeboxScope', type: 'iteration'
    chart = Ext.ComponentQuery.query('rallychart')[0]
    @spy chart, 'updateLayout'
    Ext.get('testDiv').addCls('stats-banner').addCls('collapsed')
    @gauge.onResize 100, 100
    expect(chart.updateLayout.callCount).toBe 0

  it 'should suspend and resume layouts when you refresh chart', ->
    @createGauge()
    @spy Ext, 'suspendLayouts'
    @spy Ext, 'resumeLayouts'

    @gauge.refreshChart {}
    expect(Ext.suspendLayouts.callCount).toBe 1
    expect(Ext.resumeLayouts.callCount).toBe 1

  it 'should add chart when you refresh chart', ->
    @createGauge()
    chartConfig = chartData:
      categories: [],
      series: []
    @gauge.refreshChart chartConfig
    expect(Ext.ComponentQuery.query('rallychart')[0].chartData).toEqual chartConfig.chartData

  it 'should render the chart to the correct el', ->
    @createGauge()
    el = Ext.get('testDiv').createChild()
    @stub(@gauge, 'getChartEl').returns el
    @gauge.refreshChart {}
    expect(Ext.ComponentQuery.query('rallychart')[0].getEl().parent()).toBe el

  # We need a doLayout when expanding the gauge panes otherwide the charts
  # don't line up properly if we change the data when in collapsed mode.
  # If you wanna delete this test, make sure charts look aligned if you collapse
  # the statsbanner, change some data, then reexpand the statsbanner
  it 'does a layout on the chart when expanding panel', ->
    @createGauge()
    @gauge.expand()
    expect(@gauge.chart.doLayout.callCount).toBe 1

  describe 'should generate timebox data object', ->
    beforeEach ->
      @ajax.whenQuerying('iteration').respondWith([], {
        schema:
          properties:
            EndDate:
              format:
                tzOffset: 300
      })

    it 'with null timebox', ->
      @createGauge scope: Ext.create 'Rally.app.TimeboxScope', type: 'iteration'
      @gauge.getTimeboxData().then (result) =>
        expect(result.remaining).toBe 0
        expect(result.workdays).toBe 0

    it 'with iteration timebox', ->
      @createGauge()
      @gauge.getTimeboxData().then (result) =>
        timebox = @gauge.context.getTimeboxScope().getRecord()
        expect(result).toEqual Rally.util.Timebox.getCounts(
          timebox.get('StartDate'),
          timebox.get('EndDate'),
          @gauge.context.getWorkspace().WorkspaceConfiguration.WorkDays,
          5)

  describe 'should generate acceptance data object', ->

    it 'with uncustomized schedule states', ->
      @createGauge()

      @store.add [
        @mom.getRecord 'userstory',
          values:
            PlanEstimate: 5
            ScheduleState: 'Accepted'
      , @mom.getRecord 'userstory',
          values:
            PlanEstimate: 5
            ScheduleState: 'Defined'
      ]

      expect(@gauge.getAcceptanceData().accepted).toBe 5
      expect(@gauge.getAcceptanceData().total).toBe 10

    it 'with customized schedule states', ->
      @stub Rally.test.mock.data.WsapiModelFactory.getUserStoryModel().getField('ScheduleState'), 'getAllowedStringValues', -> ['Defined', 'In-Progress', 'Completed', 'Accepted', 'Released']
      @createGauge()

      @store.add [
        @mom.getRecord 'userstory',
          values:
            PlanEstimate: 5
            ScheduleState: 'Accepted'
      ,
        @mom.getRecord 'userstory',
          values:
            PlanEstimate: 5
            ScheduleState: 'Released'
      ,
        @mom.getRecord 'userstory',
          values:
            PlanEstimate: 5
            ScheduleState: 'Defined'
      ]

      expect(@gauge.getAcceptanceData().accepted).toBe 10
      expect(@gauge.getAcceptanceData().total).toBe 15

    it 'with no plan estimates', ->
      @createGauge()

      @store.add [
        @mom.getRecord 'userstory',
          values:
            PlanEstimate: ''
            ScheduleState: 'Accepted'
      ,
        @mom.getRecord 'userstory',
          values:
            PlanEstimate: 0
            ScheduleState: 'Defined'
      ]

      expect(@gauge.getAcceptanceData().accepted).toBe 0
      expect(@gauge.getAcceptanceData().total).toBe 0

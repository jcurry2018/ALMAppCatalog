Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.util.DateTime',
  'Rally.app.Context'
]

describe 'Rally.apps.charts.iterationheatmap.IterationHeatMapApp', ->

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

      @app = Ext.create('Rally.apps.charts.iterationheatmap.IterationHeatMapApp', Ext.apply(
        context: Ext.create('Rally.app.Context',
          initialValues:
            timebox: @iterationRecord
            project:
              _ref: @projectRef
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

  beforeEach ->
    @ajax.whenReading('project').respondWith {
      TeamMembers: []
      Editors: []
    }

    @stubRequests()

  afterEach ->
    @app?.destroy()

  it 'resets view on scope change', ->
    @createApp().then =>
      removeStub = @stub(@app, 'remove')

      newScope = Ext.create('Rally.app.TimeboxScope',
        record: new @IterationModel @iterationData[1]
      )

      @app.onTimeboxScopeChange newScope

      expect(removeStub).toHaveBeenCalledOnce()
      expect(removeStub).toHaveBeenCalledWith 'heatmapChart'

      expect(@app.down('#heatmapChart')).toBeDefined()


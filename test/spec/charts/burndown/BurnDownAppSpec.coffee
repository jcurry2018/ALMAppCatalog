Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.util.DateTime'
]

describe 'Rally.apps.charts.burndown.BurnDownApp', ->
  helpers
    getContext: (initialValues) ->
      globalContext = Rally.environment.getContext()

      Ext.create 'Rally.app.Context',
        initialValues: Ext.merge(
          project: globalContext.getProject()
          workspace: globalContext.getWorkspace()
          user: globalContext.getUser()
          subscription: globalContext.getSubscription()
        , initialValues)

    getDefaultSettings: ->
      chartAggregationType: 'planestimate'
      chartDisplayType: 'line'
      chartTimebox: 'iteration'
      customScheduleStates: ['Accepted']

  describe 'app-scoped', ->
    it 'does not load twice when an iteration is current', ->
      iterations = @mom.getData 'iteration', values:
        StartDate: Rally.util.DateTime.toIsoString(Rally.util.DateTime.add(new Date(), "day", -2))
        EndDate: Rally.util.DateTime.toIsoString(Rally.util.DateTime.add(new Date(), "day", 2))

      settings = @getDefaultSettings()
      settings.chartAggregationType = 'storycount'
      @ajax.whenQuerying('iteration').respondWith iterations
      iterReadRequest = @ajax.whenReading('iteration', iterations[0].ObjectID).respondWith iterations[0]

      prefNameValues = _.map(Ext.merge({iteration: iterations[0]._ref}, settings), (value, key) -> Name: key, Value: value)
      prefRequest = @ajax.whenQuerying('preference').respondWith @mom.getData('preference', values: prefNameValues)

      addSpy = @spy()
      app = Ext.create 'Rally.apps.charts.burndown.BurnDownApp',
        context: @getContext()
        scopeType: 'iteration'
        settings: settings
        renderTo: 'testDiv'
        listeners:
          add: addSpy

      @waitForCallback(addSpy, 2).then =>
        expect(iterReadRequest.callCount).toBe 1
        expect(app.query('rallychart').length).toBe 1
        expect(app.down('rallychart').isVisible()).toBe true

    it 'maxs prediction line at 1.25 times the first ideal value', ->
      iterations = @mom.getData 'iteration', values:
        StartDate: "2013-11-01T00:00:00.000Z"
        EndDate: "2014-02-28T00:00:00.000Z"

      settings = @getDefaultSettings()

      snapshots = "[{'_ValidFrom':'2013-11-03T23:29:44.672Z','_ValidTo':'9999-01-01T00:00:00.000Z',ObjectID:14600336849,Project:4527959100,PlanEstimate:1},{'_ValidFrom':'2013-11-04T23:29:44.672Z','_ValidTo':'9999-01-01T00:00:00.000Z',ObjectID:14600336850,Project:4527959100,PlanEstimate:10}]"

      @ajax.whenQuerying('iteration').respondWith iterations
      @ajax.whenReading('iteration', iterations[0].ObjectID).respondWith iterations[0]

      prefNameValues = _.map(Ext.merge({iteration: iterations[0]._ref}, settings), (value, key) -> Name: key, Value: value)
      @ajax.whenQuerying('preference').respondWith @mom.getData('preference', values: prefNameValues)

      @ajax.whenReadingEndpoint("/snapshot/query").respondWithHtml snapshots, { url: "/analytics/v2.0/service/rally/workspace/"+@getContext().getWorkspace().ObjectID+"/artifact/snapshot/query.js", method: 'POST' }

      addSpy = @spy()
      app = Ext.create 'Rally.apps.charts.burndown.BurnDownApp',
        context: @getContext()
        scopeType: 'iteration'
        settings: settings
        renderTo: 'testDiv'
        listeners:
          add: addSpy

      testToday = new Date(2013, 10, 6, 0, 0, 0, 0) # Nov 19
      app._getNow = () -> testToday

      @waitForCallback(addSpy, 2).then =>
        rallychart = app.down 'rallychart'
        expect(rallychart.isVisible()).toBe true
        expect(_.max(rallychart.chartData.series[3].data)).toBe (1.25 * rallychart.chartData.series[2].data[0])

    it 'chartComponentConfig data structure should not be shared between apps', ->
      settings = @getDefaultSettings()

      app1 = Ext.create 'Rally.apps.charts.burndown.BurnDownApp',
        context: @getContext()
        scopeType: 'iteration'
        settings: settings
        renderTo: 'testDiv'
        title: 'test app 1'

      app2 = Ext.create 'Rally.apps.charts.burndown.BurnDownApp',
        context: @getContext()
        scopeType: 'iteration'
        settings: settings
        renderTo: 'testDiv'
        title: 'test app 2'

      app1.chartComponentConfig.chartConfig.test = 'app1'
      app2.chartComponentConfig.chartConfig.test = 'app2'
      expect(app1.chartComponentConfig.chartConfig.test).toBe('app1')


  describe 'show label config option', ->
    beforeEach ->
      addSpy = @spy()
      @app = Ext.create 'Rally.apps.charts.burndown.BurnDownApp',
        context: @getContext()
        scopeType: 'iteration'
        settings: @getDefaultSettings()
        renderTo: 'testDiv'
        listeners:
          add: addSpy

      @iteration =
        Name : "Awesome Iteration"

    it 'should show labels when the checkbox is selected', ->
      @app.settings.showLabels = true
      value = @app._buildLabelText( @iteration )
      expect(value).toBe @iteration.Name

    it 'should not show labels when the checkbox is deselected', ->
      @app.settings.showLabels = false
      value = @app._buildLabelText( @iteration )
      expect(value).toBe ""

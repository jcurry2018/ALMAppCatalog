Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.app.TimeboxScope',
  'Rally.data.wsapi.artifact.Store'
]

describe 'Rally.apps.iterationtrackingboard.statsbanner.iterationprogresscharts.MinimalPieChart', ->

  helpers
    createContext: (withRecord = true) ->
      @iterationRecord = @mom.getRecord('iteration', values: { _ref: '/iteration/1' }) if withRecord
      @context =
        getTimeboxScope: =>
          Ext.create 'Rally.app.TimeboxScope', record: @iterationRecord

    stubWsapiCalls: (options = {}) ->
      @stories = @mom.getRecords 'userstory',
        count: 1
        depth: 2
        values:
          Summary:
            Defects:
              Count: 1
            Tasks:
              Count: 2
          TestCases:
            Count: 4

      @combinedData = _.pluck(@stories, 'data')

      @ajax.whenQuerying('artifact').respondWith @combinedData
      @ajax.whenQuerying('Project').respondWith()

      @userStoryQueryForChildDefects = @ajax.whenQueryingCollection('userstory', @stories[0].getId(), 'Defects').respondWithCount 1
      @userStoryQueryForChildTasks = @ajax.whenQueryingCollection('userstory', @stories[0].getId(), 'Tasks').respondWithCount 2
      @userStoryQueryForChildTestCases = @ajax.whenQueryingCollection('userstory', @stories[0].getId(), 'TestCases').respondWithCount 4

    createStore: () ->
      @store = Ext.create 'Rally.data.wsapi.artifact.Store', {
        models: ['UserStory', 'Defect', 'DefectSuite'],
        fetch: ['Defects:summary[State;ScheduleState+Blocked]', 'PlanEstimate', 'Requirement', 'FormattedID', 'Name', 'Blocked', 'BlockedReason',
                        'ScheduleState', 'State', 'Tasks:summary[State;State+Blocked]', 'TestCases'],
        limit: Infinity,
        autoLoad: true
      }

    createChart: (config) ->
      @addSpy = @spy()
      @createContext()
      @createStore()

      chartConfig = _.merge
        context: @context
        renderTo: 'testDiv'
        store: @store
        listeners:
          add: @addSpy
      , config

      pieChart = Ext.create 'Rally.apps.iterationtrackingboard.statsbanner.iterationprogresscharts.MinimalPieChart', chartConfig
      @waitForComponentReady pieChart

    getChartConfig: ->
      _.where(_.map(@addSpy.args, (arg) ->
        arg[1]
      ), { xtype: 'rallychart' })[0]

  beforeEach ->
    @stubWsapiCalls()

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'statsbannerminimalpiechart'

  it 'should load a pie chart with data from stories', ->
    @createChart().then =>
      chartConfig = @getChartConfig()

      expect(chartConfig.chartData.series.length).toBe 2

      parentData = chartConfig.chartData.series[0].data

      expect(parentData.length).toBe @combinedData.length
      expect(parentData[0].ref).toBe @stories[0].get '_ref'

  it 'should have a slice with a Related Items count equal to the number of related items', ->
    @createChart().then =>
      chartConfig = @getChartConfig()

      expect(chartConfig.chartData.series.length).toBe 2

      parentData = chartConfig.chartData.series[0].data
      expect(parentData[0].relatedCount).toBe @combinedData[0].Summary.Defects.Count + @combinedData[0].Summary.Tasks.Count + @combinedData[0].TestCases.Count

  describe 'creating a chart', ->
    beforeEach ->
      @stubWsapiCalls allowedArtifactTypes: ['userstory', 'defect', 'testset', 'defectsuite']

    it 'should query for all possible child items', ->
      @createChart().then =>
        expect(@userStoryQueryForChildDefects).not.toHaveBeenCalled()
        expect(@userStoryQueryForChildTasks).not.toHaveBeenCalled()
        expect(@userStoryQueryForChildTestCases).not.toHaveBeenCalled()

    it 'should not have tooltips', ->
      @createChart().then =>
        chartConfig = @getChartConfig()

        expect(chartConfig.chartConfig.tooltip).toBeDefined()
        expect(chartConfig.chartConfig.tooltip.formatter).toBeAFunction()
        expect(chartConfig.chartConfig.tooltip.formatter()).toBe(false)

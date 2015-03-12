Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.app.TimeboxScope',
  'Rally.data.wsapi.artifact.Store'
]

describe 'Rally.apps.iterationtrackingboard.statsbanner.iterationprogresscharts.PieChart', ->

  helpers
    createContext: (withRecord = true) ->
      @iterationRecord = @mom.getRecord('iteration', values: { _ref: '/iteration/1' }) if withRecord
      @context =
        getTimeboxScope: =>
          Ext.create 'Rally.app.TimeboxScope', record: @iterationRecord
        getDataContext: -> Rally.environment.getContext().getDataContext()

    stubWsapiCalls: (options = {}) ->
      @stories = @mom.getRecords 'userstory',
        count: 3
        depth: 2
        values:
          Defects:
            Count: 1
          Tasks:
            Count: 2
          TestCases:
            Count: 4

      @defects = @mom.getRecords 'defect', count: 3
      @testsets = @mom.getRecords 'testset', count: 3
      @defectsuites = @mom.getRecords 'defectsuite', count: 3

      # build artifact data response to support toggle via allowedArtifactTypes
      if options.allowedArtifactTypes
        @combinedData = []

        if _.contains options.allowedArtifactTypes, 'userstory'
          @combinedData = _.pluck @stories, 'data'

        if _.contains options.allowedArtifactTypes, 'defect'
          @combinedData = @combinedData.concat _.pluck @defects, 'data'

        if _.contains options.allowedArtifactTypes, 'testset'
          @combinedData = @combinedData.concat _.pluck @testsets, 'data'

        if _.contains options.allowedArtifactTypes, 'defectsuite'
          @combinedData = @combinedData.concat _.pluck @defectsuites, 'data'

      else
        # support all types, keep this as only option once toggle is removed
        @combinedData = _.pluck(@stories, 'data').concat(_.pluck @defects, 'data').concat(_.pluck @testsets, 'data').concat(_.pluck @defectsuites, 'data')

      @ajax.whenQuerying('artifact').respondWith @combinedData
      @ajax.whenQuerying('Project').respondWith()
      @userStoryQueryForChildDefects = @ajax.whenQueryingCollection('userstory', @stories[0].getId(), 'Defects').respondWithCount 1
      @userStoryQueryForChildTasks = @ajax.whenQueryingCollection('userstory', @stories[0].getId(), 'Tasks').respondWithCount 2
      @userStoryQueryForChildTestCases = @ajax.whenQueryingCollection('userstory', @stories[0].getId(), 'TestCases').respondWithCount 4

    createChart: (config) ->
      @addSpy = @spy()
      @createContext()

      chartConfig = _.merge
        context: @context
        renderTo: 'testDiv'
        listeners:
          add: @addSpy
      , config

      pieChart = Ext.create 'Rally.apps.iterationtrackingboard.statsbanner.iterationprogresscharts.PieChart', chartConfig
      @waitForComponentReady pieChart

    getChartConfig: ->
      _.where(_.map(@addSpy.args, (arg) ->
        arg[1]
      ), { xtype: 'rallychart' })[0]

  beforeEach ->
    @stubWsapiCalls()

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'statsbannerpiechart'

  it 'should load a pie chart with data from stories', ->
    @createChart().then =>
      chartConfig = @getChartConfig()

      expect(chartConfig.chartData.series.length).toBe 2

      parentData = chartConfig.chartData.series[0].data

      expect(parentData.length).toBe @combinedData.length
      expect(parentData[0].ref).toBe @stories[0].get '_ref'
      expect(parentData[1].ref).toBe @stories[1].get '_ref'
      expect(parentData[2].ref).toBe @stories[2].get '_ref'

  it 'should have a slice with a Related Items count equal to the number of related items', ->
    @createChart().then =>
      chartConfig = @getChartConfig()

      expect(chartConfig.chartData.series.length).toBe 2

      parentData = chartConfig.chartData.series[0].data
      expect(parentData[0].relatedCount).toBe @combinedData[0].Defects.Count + @combinedData[0].Tasks.Count + @combinedData[0].TestCases.Count

  describe 'creating a chart', ->
    beforeEach ->
      @stubWsapiCalls allowedArtifactTypes: ['userstory', 'defect', 'testset', 'defectsuite']

    it 'should query for all possible child items', ->
      @createChart().then =>
        expect(@userStoryQueryForChildDefects).toHaveBeenCalled()
        expect(@userStoryQueryForChildTasks).toHaveBeenCalled()
        expect(@userStoryQueryForChildTestCases).toHaveBeenCalled()

 
    it 'should have tooltips', ->
      @createChart().then =>
        chartConfig = @getChartConfig()

        expect(chartConfig.chartConfig.tooltip).toBeDefined()
        expect(chartConfig.chartConfig.tooltip.formatter).toBeAFunction()

        formatter = chartConfig.chartConfig.tooltip.formatter
        result = formatter.call(point: {})
        expect(result).toBeAString()

  describe 'destroy', ->
    it 'should reset chart pointer', ->
      @createChart().then (chart) =>
        @once(
          condition: => chart.down('rallychart') && chart.down('rallychart').getChart()
        ).then =>
          resetSpy = @spy chart.down('rallychart').getChart().pointer, 'reset'
          chart.destroy()
          expect(resetSpy.callCount).toBe 1


Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.util.RoadmapGenerator'
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
]

describe 'Rally.apps.roadmapplanningboard.util.RoadmapGenerator', ->

  helpers
    getDateRange: (timeframeRecord) ->
      startDate: Ext.Date.format(timeframeRecord.get('startDate'), @dateFormat)
      endDate: Ext.Date.format(timeframeRecord.get('endDate'), @dateFormat)

    getTimeframeMock: (index) ->
      ref: "/timeframe/#{index}"
      id: index

    getTimelineMock: (timeframeCount = 1) ->
      timeframes: if timeframeCount <= 0 then [] else _.map [1..timeframeCount], (index) => @getTimeframeMock(index)

    emptyStores: ->
      @timelineRoadmapStoreWrapper.roadmapStore.data.clear()
      @timelineRoadmapStoreWrapper.timelineStore.data.clear()

    createCompleteRoadmapData: ->
      @generator.createCompleteRoadmapData().then ({@roadmap, @timeline}) =>

    createRoadmapGivenATimeline: (timeframeCount = 1) ->
      @timelineRoadmapStoreWrapper.timelineStore.add @getTimelineMock(timeframeCount)
      @createCompleteRoadmapData()

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @dateFormat = 'Y-m-d'
    @stub Ext.Date, 'now', => Ext.Date.parse('2014-01-24', @dateFormat).getTime()
    @workspace = Name: 'Some Workspace'
    @timelineRoadmapStoreWrapper = Ext.create 'Rally.apps.roadmapplanningboard.util.TimelineRoadmapStoreWrapper'

    @generator = Ext.create 'Rally.apps.roadmapplanningboard.util.RoadmapGenerator',
      timelineRoadmapStoreWrapper: @timelineRoadmapStoreWrapper
      workspace: @workspace

    @createTimelineSpy = @spy @generator, '_createTimeline'
    @createRoadmapSpy = @spy @generator, '_createRoadmap'

  describe 'timeline exists but no roadmap exists', ->

    beforeEach ->
      @emptyStores()

    it 'should add a new roadmap record to the roadmap store', ->
      @createRoadmapGivenATimeline().then =>
        expect(@timelineRoadmapStoreWrapper.roadmapStore.last().id).toBe @roadmap.id

    it 'should set the new roadmap name to include the workspace name', ->
      @createRoadmapGivenATimeline().then =>
        expect(@roadmap.get('name')).toBe "#{@workspace.Name} Roadmap"

    it 'should set the timeframe for each plan', ->
      @createRoadmapGivenATimeline().then =>
        expect(@roadmap.get('plans')[0].get('timeframe').ref).toBe @timeline.get('timeframes')[0].ref

    it 'should throw an exception if the timeline does not have timeframes', ->
      expect(@createRoadmapGivenATimeline 0).toRejectWith 'Timeline must contain timeframes'

    it 'should create a plan for a timeline with a single timeframe', ->
      @createRoadmapGivenATimeline().then =>
        expect(@roadmap.get('plans').length).toBe 1

    it 'should create a plan for a timeline with multiple timeframes', ->
      @createRoadmapGivenATimeline(4).then =>
        expect(@roadmap.get('plans').length).toBe 4

    it 'should not create a timeline', ->
      @createRoadmapGivenATimeline().then =>
        expect(@createTimelineSpy).not.toHaveBeenCalled()

    describe 'request to service', ->
      beforeEach ->
        @timelineRoadmapStoreWrapper.roadmapStore.model.setProxy
          type: 'roadmap'
          url: '/planning/service/url'
        @ajaxStub = @stub Ext.Ajax, 'request', (options) ->
          options.callback.call options.scope, options, true
        @createRoadmapGivenATimeline()

      it 'should set method to POST', ->
        expect(@ajaxStub.lastCall.args[0].method).toBe 'POST'

      it 'should include a plan in jsonData', ->
        expect(@ajaxStub.lastCall.args[0].jsonData.plans.length).toBe 1

  describe 'no roadmap or timeline exist', ->

    beforeEach ->
      @emptyStores()
      @createCompleteRoadmapData()

    it 'should add a new timeline record to the timeline store', ->
      expect(@timelineRoadmapStoreWrapper.timelineStore.last().id).toBe @timeline.id

    it 'should set the new timeline name to include the workspace name', ->
      expect(@timeline.get('name')).toBe "#{@workspace.Name} Timeline"

    it 'should create a single timeframe for the timeline', ->
      expect(@timeline.get('timeframes').length).toBe 1

    it 'should set the timeframe date range to the current quarter', ->
      expect(@getDateRange(_.first(@timeline.get('timeframes')))).toEqual
        startDate: '2014-01-01'
        endDate: '2014-03-31'

    it 'should set the timeframe name to New Timeframe', ->
      expect(_.first(@timeline.get('timeframes')).get('name')).toBe 'New Timeframe'

    it 'should create a timeline before creating a roadmap', ->
      sinon.assert.callOrder @createTimelineSpy, @createRoadmapSpy

  describe 'roadmap and timeline both exist', ->

    beforeEach ->
      @createCompleteRoadmapData()

    it 'should not create a roadmap', ->
      expect(@createRoadmapSpy).not.toHaveBeenCalled()

    it 'should not create a timeline', ->
      expect(@createTimelineSpy).not.toHaveBeenCalled()

  describe 'roadmap exists but no timeline exists', ->

    beforeEach ->
      @timelineRoadmapStoreWrapper.timelineStore.data.clear()

    it 'should throw an error', ->
      expect(@createCompleteRoadmapData()).toRejectWith 'Cannot create a timeline when a roadmap already exists'
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
      timeframes = if timeframeCount <= 0 then [] else _.map [1..timeframeCount], (index) => @getTimeframeMock(index)
      get: -> timeframes

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @dateFormat = 'Y-m-d'
    @stub Ext.Date, 'now', => Ext.Date.parse('2014-01-24', @dateFormat).getTime()
    @workspace =
      Name: 'Some Workspace'
    @timelineStore = Deft.Injector.resolve('timelineStore')
    @roadmapStore = Deft.Injector.resolve('roadmapStore')
    @generator = Ext.create 'Rally.apps.roadmapplanningboard.util.RoadmapGenerator',
      roadmapStore: @roadmapStore
      timelineStore: @timelineStore
      workspace: @workspace

  describe 'creating a roadmap', ->
    it 'should add a new roadmap record to the roadmap store', ->
      @generator.createRoadmap(@getTimelineMock()).then (@roadmapRecord) =>
        expect(@roadmapStore.last().id).toBe @roadmapRecord.id

    it 'should set the new roadmap name to include the workspace name', ->
      @generator.createRoadmap(@getTimelineMock()).then (@roadmapRecord) =>
        expect(@roadmapRecord.get('name')).toBe "#{@workspace.Name} Roadmap"

    it 'should set the timeframe for each plan', ->
      timeline = @getTimelineMock()
      @generator.createRoadmap(timeline).then (@roadmapRecord) =>
        expect(@roadmapRecord.get('plans')[0].get('timeframe').ref).toBe timeline.get('timeframes')[0].ref

    it 'should throw an exception if the timeline does not have timeframes', ->
      createRoadmap = =>
        @generator.createRoadmap @getTimelineMock(0)
      expect(createRoadmap).toThrow 'Timeline must contain timeframes'

    it 'should create a plan for a timeline with a single timeframe', ->
      @generator.createRoadmap(@getTimelineMock()).then (@roadmapRecord) =>
        expect(@roadmapRecord.get('plans').length).toBe 1

    it 'should create a plan for a timeline with multiple timeframes', ->
      @generator.createRoadmap(@getTimelineMock(4)).then (@roadmapRecord) =>
        expect(@roadmapRecord.get('plans').length).toBe 4

    describe 'request to service', ->
      beforeEach ->
        @roadmapStore.model.setProxy
          type: 'roadmap'
          url: '/planning/service/url'
        @ajaxStub = @stub Ext.Ajax, 'request', (options) ->
          options.callback.call options.scope, options, true
        @generator.createRoadmap @getTimelineMock()

      it 'should set method to POST', ->
        expect(@ajaxStub.lastCall.args[0].method).toBe 'POST'

      it 'should include a plan in jsonData', ->
        expect(@ajaxStub.lastCall.args[0].jsonData.plans.length).toBe 1


  describe 'creating a timeline', ->
    beforeEach ->
      @generator.createTimeline().then (@timelineRecord) =>

    it 'should add a new timeline record to the timeline store', ->
      expect(@timelineStore.last().id).toBe @timelineRecord.id

    it 'should set the new timeline name to include the workspace name', ->
      expect(@timelineRecord.get('name')).toBe "#{@workspace.Name} Timeline"

    it 'should create a single timeframe for the timeline', ->
      expect(@timelineRecord.get('timeframes').length).toBe 1

    it 'should set the timeframe date range to the current quarter', ->
      expect(@getDateRange(_.first(@timelineRecord.get('timeframes')))).toEqual
        startDate: '2014-01-01'
        endDate: '2014-03-31'

    it 'should set the timeframe name to New Timeframe', ->
      expect(_.first(@timelineRecord.get('timeframes')).get('name')).toBe 'New Timeframe'

  describe 'creating both a timeline and a roadmap', ->

    it 'should create a timeline before creating a roadmap', ->
      createTimelineSpy = @spy @generator, 'createTimeline'
      createRoadmapSpy = @spy @generator, 'createRoadmap'
      @generator.createTimelineRoadmap().then =>
        sinon.assert.callOrder createTimelineSpy, createRoadmapSpy
Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper'
]

describe 'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper', ->

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()

    roadmap = Deft.Injector.resolve('roadmapStore').first()
    timeline = Deft.Injector.resolve('timelineStore').first()
    requester = name: 'some requester'

    requesterMatcher = sinon.match ((value) -> value.requester.name is requester.name), 'that contain the passed requester'
    @timeframeMatcher = requesterMatcher.and sinon.match(((value) -> value.params.timeline.id is timeline.getId()), 'that contain the passed params')
    @planMatcher = requesterMatcher.and sinon.match(((value) -> value.params.roadmap.id is roadmap.getId()), 'that contain the passed params')

    @wrapper = Ext.create 'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper',
      requester: requester
      roadmap: roadmap
      timeline: timeline

  describe '#getTimeframeAndPlanRecords', ->

    it 'should only get timeframe records that are associated with plans', ->
      expect(@wrapper.getTimeframeAndPlanRecords().length).toBe 4

  describe '#load', ->
    beforeEach ->
      @timeframeStoreLoadSpy = @spy @wrapper.timeframeStore, 'load'
      @planStoreLoadSpy = @spy @wrapper.planStore, 'load'
      @wrapper.load().then =>

    it 'should load the plan store', ->
      expect(@planStoreLoadSpy).toHaveBeenCalledOnce()

    it 'should load the plan store with the correct arguments', ->
      # Use the sinon assert syntax since error messages read better
      sinon.assert.calledWith(@planStoreLoadSpy, @planMatcher)

    it 'should load the timeframe store', ->
      expect(@timeframeStoreLoadSpy).toHaveBeenCalledOnce()

    it 'should load the timeframe store with the correct arguments', ->
      # Use the sinon assert syntax since error messages read better
      sinon.assert.calledWith(@timeframeStoreLoadSpy, @timeframeMatcher)
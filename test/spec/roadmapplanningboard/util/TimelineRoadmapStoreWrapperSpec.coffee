Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper',
  'Rally.apps.roadmapplanningboard.util.TimelineRoadmapStoreWrapper'
]

describe 'Rally.apps.roadmapplanningboard.util.TimelineRoadmapStoreWrapper', ->
  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()

    requester =
      name: 'some requester'
    @requesterMatcher = sinon.match ((value) -> value.requester.name is requester.name), 'that contain the passed requester'
    @wrapper = Ext.create 'Rally.apps.roadmapplanningboard.util.TimelineRoadmapStoreWrapper',
      requester: requester


  describe '#load', ->
    beforeEach ->
      @timelineStoreLoadSpy = @spy @wrapper.timelineStore, 'load'
      @roadmapStoreLoadSpy = @spy @wrapper.roadmapStore, 'load'
      @wrapper.load().then ({@roadmap, @timeline}) =>

    it 'should load the roadmap store', ->
      expect(@roadmapStoreLoadSpy).toHaveBeenCalledOnce()

    it 'should load the roadmap store with the specified requester', ->
      # Use the sinon assert syntax since error messages read better
      sinon.assert.calledWith(@roadmapStoreLoadSpy, @requesterMatcher)

    it 'should load the timeline store', ->
      expect(@timelineStoreLoadSpy).toHaveBeenCalledOnce()

    it 'should load the timeline store with the specified requester', ->
      # Use the sinon assert syntax since error messages read better
      sinon.assert.calledWith(@timelineStoreLoadSpy, @requesterMatcher)

    it 'should resolve with an object containing a roadmap', ->
      expect(@roadmap.getId()).toBe 'roadmap-id-1'

    it 'should resolve with an object containing a roadmap', ->
      expect(@timeline.getId()).toBe 'timeline-id-1'

  describe '#hasTimeline', ->
    it 'should return true when the timeline store contains records', ->
      expect(@wrapper.hasTimeline()).toBe true

    it 'should return false when the timeline store contains no records', ->
      @wrapper.timelineStore.data.clear()
      expect(@wrapper.hasTimeline()).toBe false

  describe '#hasRoadmap', ->
    it 'should return true when the roadmap store contains records', ->
      expect(@wrapper.hasRoadmap()).toBe true

    it 'should return false when the roadmap store contains no records', ->
      @wrapper.roadmapStore.data.clear()
      expect(@wrapper.hasRoadmap()).toBe false
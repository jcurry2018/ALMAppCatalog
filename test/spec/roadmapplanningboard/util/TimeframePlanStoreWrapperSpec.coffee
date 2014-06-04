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

    beforeEach ->
      @timeframePlans = @wrapper.getTimeframeAndPlanRecords()

    it 'should only get timeframe records that are associated with plans', ->
      expect(@timeframePlans.length).toBe 4

    it 'should sync the timeframe and plan names', ->
      timeframe = @wrapper.timeframeStore.first()
      plan = @wrapper.planStore.first()
      expect(plan.get 'name').toBe timeframe.get 'name'

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

  describe '#deletePlan', ->

    beforeEach ->
      @planRecordToDelete = @wrapper.planStore.first()

    it 'should return a promise', ->
      expect(@wrapper.deletePlan(@planRecordToDelete).then).toBeDefined()

    it 'should delete the plan from the plan store', ->
      @wrapper.deletePlan(@planRecordToDelete)
      expect(@wrapper.planStore.findRecord('id', @planRecordToDelete.getId())).toBeNull()

    it 'should not delete the timeframe from the timeframe store', ->
      timeframe = @planRecordToDelete.get('timeframe')
      @wrapper.deletePlan(@planRecordToDelete)
      expect(@wrapper.timeframeStore.findRecord('id', timeframe.id)).toBeDefined()

  describe 'timeframe update', ->

    it 'should update the name of the associated plan', ->
      newName = 'new plan name'
      timeframe = @wrapper.timeframeStore.first()
      plan = @wrapper.planStore.first()
      timeframe.set 'name', newName
      timeframe.save()
      expect(plan.get 'name').toBe newName





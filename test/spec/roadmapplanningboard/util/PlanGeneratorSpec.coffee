Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.util.PlanGenerator'
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
]

describe 'Rally.apps.roadmapplanningboard.util.PlanGenerator', ->
  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @timeframeStore = Deft.Injector.resolve('timeframeStore')
    @planStore = Deft.Injector.resolve('planStore')
    @generator = Ext.create 'Rally.apps.roadmapplanningboard.util.PlanGenerator',
      roadmap: Deft.Injector.resolve('roadmapStore').first()
      timeframePlanStoreWrapper: Ext.create('Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper',
        timeframeStore: @timeframeStore
        planStore: @planStore
      )

  describe '#createPlanWithTimeframe', ->
    beforeEach ->
      @generator.createPlanWithTimeframe().then ({@planRecord, @timeframeRecord}) =>

    it 'should add a plan to the plan store', ->
      expect(@planStore.last().getId()).toBe @planRecord.getId()

    it 'should set the timeframe on the plan', ->
      expect(@planRecord.get('timeframe').getId()).toBe @timeframeRecord.getId()
      
    it 'should add a timeframe to the timeframe store', ->
      expect(@timeframeStore.last().getId()).toBe @timeframeRecord.getId()
     
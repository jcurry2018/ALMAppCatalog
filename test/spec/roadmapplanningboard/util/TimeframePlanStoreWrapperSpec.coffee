Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper'
]

describe 'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper', ->

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    timeframeStore = Deft.Injector.resolve('timeframeStore')
    planStore = Deft.Injector.resolve('planStore')

    @wrapper = Ext.create 'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper',
      timeframeStore: timeframeStore
      planStore: planStore

  describe '#getTimeframeAndPlanRecords', ->

    it 'should only get timeframe records that are associated with plans', ->
      expect(@wrapper.getTimeframeAndPlanRecords().length).toBe 4
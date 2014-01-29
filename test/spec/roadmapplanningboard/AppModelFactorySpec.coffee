Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.AppModelFactory',
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
]
describe 'Rally.apps.roadmapplanningboard.AppModelFactory', ->

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()

  describe '#normalizeDate', ->
    it 'should set the date correct local day', ->
      date = Rally.apps.roadmapplanningboard.AppModelFactory._normalizeDate('2013-10-01T06:00:00Z')
      expect(Ext.Date.format(date, 'd')).toBe '01'

  describe 'plan model', ->
    it 'should serialize timeframe data', ->
      plan = Deft.Injector.resolve('planStore').first()
      timeframe = plan.get('timeframe')
      expect(plan.getField('timeframe').serialize(timeframe, plan)).toEqual timeframe

  describe 'timeline model', ->
    it 'should serialize timeframes collection', ->
      timeline = Deft.Injector.resolve('timelineStore').first()
      timeframes = timeline.get('timeframes')
      expect(timeline.getField('timeframes').serialize(timeframes, timeline)).toEqual timeframes

  describe 'roadmap model', ->
    it 'should serialize plans collection', ->
      roadmap = Deft.Injector.resolve('roadmapStore').first()
      plans = roadmap.get('plans')
      expect(roadmap.getField('plans').serialize(plans, roadmap)).toEqual plans
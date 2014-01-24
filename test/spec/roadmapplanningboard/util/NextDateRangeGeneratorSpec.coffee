Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.util.NextDateRangeGenerator'
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
]

describe 'Rally.apps.roadmapplanningboard.util.NextDateRangeGenerator', ->

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @nextDateRangeGenerator = Deft.Injector.resolve 'nextDateRangeGenerator'
    @format = 'Y-m-d'

  afterEach ->
    Deft.Injector.reset()

  describe '#isWeeks', ->
    expectedResults =
      0: false
      1: false
      2: false
      3: false
      4: false
      5: false
      6: true
      7: false
      8: false
      13: true
      14: false
      20: true
      21: false

    _.each expectedResults, (expected, input) ->
      it "should evaluate #{input} days correctly", ->
        expect(@nextDateRangeGenerator.isWeeks(+input)).toBe expected

  describe '#isQuarter', ->
    expectedResults = [
      { startDate: '2014-01-01', endDate: '2014-03-31', expected: true }
      { startDate: '2014-04-01', endDate: '2014-06-30', expected: true }
      { startDate: '2014-07-01', endDate: '2014-09-30', expected: true }
      { startDate: '2014-10-01', endDate: '2014-12-31', expected: true }
      { startDate: '2014-01-01', endDate: '2014-12-31', expected: false }
    ]

    _.each expectedResults, ({startDate, endDate, expected}) =>
      it "should evaluate date range #{startDate} to #{endDate} correctly", ->
        expect(@nextDateRangeGenerator.isQuarter(Ext.Date.parse(startDate, @format), Ext.Date.parse(endDate, @format))).toBe expected

  describe '#getQuarter', ->
    expectedResults = [
      { input: '2014-01-01', expected: { start: '2014-01-01', end: '2014-03-31' } }
      { input: '2014-02-01', expected: { start: '2014-01-01', end: '2014-03-31' } }
      { input: '2014-03-31', expected: { start: '2014-01-01', end: '2014-03-31' } }
      { input: '2014-04-01', expected: { start: '2014-04-01', end: '2014-06-30' } }
      { input: '2014-05-01', expected: { start: '2014-04-01', end: '2014-06-30' } }
      { input: '2014-06-30', expected: { start: '2014-04-01', end: '2014-06-30' } }
      { input: '2014-07-01', expected: { start: '2014-07-01', end: '2014-09-30' } }
      { input: '2014-08-01', expected: { start: '2014-07-01', end: '2014-09-30' } }
      { input: '2014-09-30', expected: { start: '2014-07-01', end: '2014-09-30' } }
      { input: '2014-10-01', expected: { start: '2014-10-01', end: '2014-12-31' } }
      { input: '2014-11-01', expected: { start: '2014-10-01', end: '2014-12-31' } }
      { input: '2014-12-31', expected: { start: '2014-10-01', end: '2014-12-31' } }
    ]

    _.each expectedResults, ({input, expected}) =>
      it "should evaluate #{input} to be in correct quarter", ->
        expect(@nextDateRangeGenerator.getQuarter(Ext.Date.parse(input, @format))).toEqual expected

  describe 'dates', ->
    timeFrameData = [
      { startDate: null, endDate: null, nextStartDate: '2014-10-01', nextEndDate: '2014-12-31T23:59:59Z-00:00' }
      { startDate: '2014-01-01', endDate: '2014-01-14', nextStartDate: '2014-01-15', nextEndDate: '2014-01-28T23:59:59Z-00:00' }
      { startDate: '2014-01-13', endDate: '2014-01-21', nextStartDate: '2014-01-22', nextEndDate: '2014-03-31T23:59:59Z-00:00' }
      { startDate: '2014-04-01', endDate: '2014-06-30', nextStartDate: '2014-07-01', nextEndDate: '2014-09-30T23:59:59Z-00:00' }
      { startDate: '2014-04-01', endDate: '2014-06-27', nextStartDate: '2014-06-28', nextEndDate: '2014-06-30T23:59:59Z-00:00' }
      { startDate: '2014-10-01', endDate: '2014-12-31', nextStartDate: '2015-01-01', nextEndDate: '2015-03-31T23:59:59Z-00:00' }
    ]

    beforeEach ->
      @stub Ext.Date, 'now', -> Ext.Date.parse '2014-10-16', 'Y-m-d'

    describe '#getStartDate', ->
      _.each timeFrameData, ({startDate, endDate, nextStartDate, nextEndDate}) =>
        it "should evaluate #{startDate} to #{endDate} to correct next dates", ->
          expect(@nextDateRangeGenerator.getNextStartDate(endDate && Ext.Date.parse(endDate, @format))).toEqual Ext.Date.parse(nextStartDate, @format)

    describe '#getEndDate', ->
      _.each timeFrameData, ({startDate, endDate, nextStartDate, nextEndDate}) =>
        it "should evaluate #{startDate} to #{endDate} to correct next dates", ->
          expect(@nextDateRangeGenerator.getNextEndDate(Ext.Date.parse(startDate, @format), Ext.Date.parse(endDate, @format))).toEqual Ext.Date.parse(nextEndDate, "#{@format}\\TH:i:s\\ZP")

Ext = window.Ext4 || window.Ext;


Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper'
  'Rally.apps.roadmapplanningboard.util.TimelineViewModel'
]

describe 'Rally.apps.roadmapplanningboard.util.TimelineViewModel', ->
  helpers
    createTimeframe: (startDate, endDate) ->
      startDate: new Date(startDate) if startDate
      endDate: new Date(endDate) if endDate

    createTimeline: (config) ->
      Ext.create 'Rally.apps.roadmapplanningboard.util.TimelineViewModel', config

  describe 'static methods', ->
    beforeEach ->
      Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
      timeframeStore = Deft.Injector.resolve('timeframeStore')
      planStore = Deft.Injector.resolve('planStore')

      @wrapper = Ext.create 'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper',
        timeframeStore: timeframeStore
        planStore: planStore

      @timeframeRecord = Ext.create Rally.apps.roadmapplanningboard.AppModelFactory.getTimeframeModel(),
        name: 'Q1'
        startDate: new Date('04/01/2013')
        endDate: new Date('06/30/2013')

      @viewModel = Rally.apps.roadmapplanningboard.util.TimelineViewModel.createFromStores(@wrapper, @timeframeRecord)

    describe '#createFromStores', ->
      it 'should create a view model with the current timeline', ->
        expect(@viewModel.currentTimeframe).toEqual
          startDate: @timeframeRecord.get('startDate')
          endDate: @timeframeRecord.get('endDate')

      it 'should create a view model with the correct number of time frames', ->
        expect(@viewModel.timeframes.length).toBe 3

  describe 'instance methods', ->
    beforeEach ->
      @timelineModel = @createTimeline
        timeframes: [
          @createTimeframe '02/01/2014', '02/28/2014'
          @createTimeframe '03/01/2014', '03/31/2014'
          @createTimeframe '01/01/2014', '01/31/2014'
          @createTimeframe '04/01/2014', '04/30/2014'
        ],
        currentTimeframe:
          @createTimeframe '02/01/2014', '02/28/2014'

    describe '#constructor', ->
      it 'should sort timeframes by start date', ->
        expect(@timelineModel.timeframes[0]).toEqual @createTimeframe '01/01/2014', '01/31/2014'

      it 'should remove the current timeframe from timeframes', ->
        expect(@timelineModel.timeframes).not.toContain @timelineModel.currentTimeframe

    describe '#getNextTimeframe', ->
      it 'should get the next timeframe', ->
        expect(@timelineModel.getNextTimeframe()).toEqual @createTimeframe '03/01/2014', '03/31/2014'

      it 'should return null if the current timeframe is the last timeframe', ->
        @timelineModel.currentTimeframe =
          startDate: '05/01/2014'
          endDate: '05/31/2014'
        expect(@timelineModel.getNextTimeframe()).toBeNull()

      it 'should get the next timeframe if endDate date is null', ->
        @timelineModel.currentTimeframe =
          startDate: @timelineModel.currentTimeframe.startDate
          endDate: null
        expect(@timelineModel.getNextTimeframe()).toEqual @createTimeframe '03/01/2014', '03/31/2014'

      it 'should return null if start date and end dates are null', ->
        @timelineModel.currentTimeframe =
          startDate: null
          endDate: null
        expect(@timelineModel.getNextTimeframe()).toBeNull()

    describe '#getPreviousTimeframe', ->
      it 'should get the previous timeframe', ->
        expect(@timelineModel.getPreviousTimeframe()).toEqual @createTimeframe '01/01/2014', '01/31/2014'

      it 'should return null if the current timeframe is the first timeframe', ->
        @timelineModel.currentTimeframe =
          startDate: '12/01/2013'
          endDate: '12/31/2013'
        expect(@timelineModel.getPreviousTimeframe()).toBeNull()

      it 'should get the previous timeframe if start date is null', ->
        @timelineModel.currentTimeframe =
          startDate: null
          endDate: @timelineModel.currentTimeframe.endDate
        expect(@timelineModel.getPreviousTimeframe()).toEqual @createTimeframe '01/01/2014', '01/31/2014'

      it 'should return last timeframe if start date and end dates are null', ->
        @timelineModel.currentTimeframe =
          startDate: null
          endDate: null
        expect(@timelineModel.getPreviousTimeframe()).toEqual @createTimeframe '04/01/2014', '04/30/2014'

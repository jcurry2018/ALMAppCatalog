Ext = window.Ext4 || window.Ext;


Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper'
  'Rally.apps.roadmapplanningboard.util.TimelineViewModel'
]

describe 'Rally.apps.roadmapplanningboard.util.TimelineViewModel', ->
  helpers
    createTimeframe: (start, end) ->
      start: new Date(start) if start
      end: new Date(end) if end

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
        start: new Date('04/01/2013')
        end: new Date('06/30/2013')

      @viewModel = Rally.apps.roadmapplanningboard.util.TimelineViewModel.createFromStores(@wrapper, @timeframeRecord)

    describe '#createFromStores', ->
      it 'should create a view model with the current timeline', ->
        expect(@viewModel.currentTimeframe).toEqual
          start: @timeframeRecord.get('startDate')
          end: @timeframeRecord.get('endDate')

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
          start: '05/01/2014'
          end: '05/31/2014'
        expect(@timelineModel.getNextTimeframe()).toBeNull()

      it 'should get the next timeframe if end date is null', ->
        @timelineModel.currentTimeframe =
          start: @timelineModel.currentTimeframe.start
          end: null
        expect(@timelineModel.getNextTimeframe()).toEqual @createTimeframe '03/01/2014', '03/31/2014'

      it 'should return null if start date and end dates are null', ->
        @timelineModel.currentTimeframe =
          start: null
          end: null
        expect(@timelineModel.getNextTimeframe()).toBeNull()

    describe '#getPreviousTimeframe', ->
      it 'should get the previous timeframe', ->
        expect(@timelineModel.getPreviousTimeframe()).toEqual @createTimeframe '01/01/2014', '01/31/2014'

      it 'should return null if the current timeframe is the first timeframe', ->
        @timelineModel.currentTimeframe =
          start: '12/01/2013'
          end: '12/31/2013'
        expect(@timelineModel.getPreviousTimeframe()).toBeNull()

      it 'should get the previous timeframe if start date is null', ->
        @timelineModel.currentTimeframe =
          start: null
          end: @timelineModel.currentTimeframe.end
        expect(@timelineModel.getPreviousTimeframe()).toEqual @createTimeframe '01/01/2014', '01/31/2014'

      it 'should return last timeframe if start date and end dates are null', ->
        @timelineModel.currentTimeframe =
          start: null
          end: null
        expect(@timelineModel.getPreviousTimeframe()).toEqual @createTimeframe '04/01/2014', '04/30/2014'

    describe '#setCurrentTimeframe', ->

      it 'should update current timeframe if new timeframe is a valid range and does not overlap', ->
        newTimeframe = @createTimeframe '02/02/2014', '02/27/2014'
        @timelineModel.setCurrentTimeframe newTimeframe
        expect(@timelineModel.currentTimeframe).toEqual newTimeframe

      it 'should not allow the start date to be before the end date', ->
        newTimeframe = @createTimeframe '04/01/2014', '03/31/2014'
        expect(=> @timelineModel.setCurrentTimeframe(newTimeframe)).toThrow 'Start date is after end date'

      it 'should not allow start date to be before previous end date', ->
        newTimeframe = @createTimeframe '01/30/2014', '02/28/2014'
        expect(=> @timelineModel.setCurrentTimeframe(newTimeframe)).toThrow 'Start date overlaps an earlier timeframe'

      it 'should not allow end date to be after next start date', ->
        newTimeframe = @createTimeframe '02/01/2014', '03/03/2014'
        expect(=> @timelineModel.setCurrentTimeframe(newTimeframe)).toThrow 'End date overlaps a later timeframe'

      it 'should not update the current timeframe when you pass in invalid dates', ->
        expect(=>
          @timelineModel.setCurrentTimeframe
            start: 'junk',
            end: @timelineModel.currentTimeframe.end
        ).toThrow 'Start and end date must be valid dates'

      describe 'start date is null', ->
        it 'should pass if end date does not overlap a timeframe', ->
          newTimeframe = @createTimeframe null, '02/28/2014'
          @timelineModel.setCurrentTimeframe(newTimeframe)
          expect(@timelineModel.currentTimeframe).toEqual newTimeframe

        it 'should fail if end date overlaps a timeframe', ->
          newTimeframe = @createTimeframe null, '03/02/2014'
          expect(=> @timelineModel.setCurrentTimeframe(newTimeframe)).toThrow 'End date overlaps a later timeframe'

      describe 'end date is null', ->
        it 'should pass if start date does not overlap a timeframe', ->
          newTimeframe = @createTimeframe '02/01/2014', null
          @timelineModel.setCurrentTimeframe(newTimeframe)
          expect(@timelineModel.currentTimeframe).toEqual newTimeframe

        it 'should fail if start date overlaps a timeframe', ->
          newTimeframe = @createTimeframe '01/30/2014', null
          expect(=> @timelineModel.setCurrentTimeframe(newTimeframe)).toThrow 'Start date overlaps an earlier timeframe'
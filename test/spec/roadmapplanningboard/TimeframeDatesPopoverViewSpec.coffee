Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.TimeframeDatesPopoverView'
]

describe 'Rally.apps.roadmapplanningboard.TimeframeDatesPopoverView', ->
  helpers
    createTimeframe: (startDate, endDate) ->
      startDate: new Date(startDate) if startDate
      endDate: new Date(endDate) if endDate

    createTimeline: (config) ->
      Ext.create 'Rally.apps.roadmapplanningboard.util.TimelineViewModel', config

    validPicker: (dateField) ->
      expect(@view.picker.isVisible()).toBe(true)
      expect(@view.picker.getValue().getTime()).toEqual(dateField.getValue().getTime())

    writeTo: (dateField, data) ->
      dateField.setValue('')
      @sendKeys(dateField.inputEl.dom, data)

  beforeEach ->
    @view = Ext.create 'Rally.apps.roadmapplanningboard.TimeframeDatesPopoverView',
      target: Ext.get 'testDiv'
      waitTimeForDateFieldValidation: 0
      timelineViewModel: @createTimeline
        timeframes: [
          @createTimeframe '02/01/2014', '02/28/2014'
          @createTimeframe '03/01/2014', '03/31/2014'
          @createTimeframe '01/01/2014', '01/31/2014'
        ],
        currentTimeframe:
          @createTimeframe '02/01/2014', '02/28/2014'

    @destroySpy = @spy @view, 'destroy'
    @saveStub = @stub()
    @view.addListener 'save', @saveStub

    @doneButton = @view.down('#datesDone')
    @cancelButton = @view.down('#datesCancel')

  afterEach ->
    @view?.destroy()

  it 'should NOT create picker when field is focused',  ->
    @click(@view.endDate.getEl()).then =>
      expect(!!@view.picker).toBe false

  it 'should create picker when trigger is clicked', ->
    @click(@view.startDate.triggerEl.first()).then =>
      expect(!!@view.picker).toBe true

  it 'should reflect dates in picker based on whichever field has current focus', ->
    if !Ext.isGecko
      @click(@view.startDate.triggerEl.first()).then =>
        # be extra specific about the element we click to make Firefox happy
        @click(@view.endDate.getEl().down('input').dom).then =>
          @validPicker(@view.endDate)

  it 'should not call validation on change before the done button has been clicked', ->
    validatorSpy = @spy @view.startDate, 'validator'
    @view.startDate.setValue('junk');
    expect(validatorSpy).not.toHaveBeenCalled()

  it 'should call validation on both fields when the done button is clicked', ->
    startValidatorSpy = @spy @view.startDate, 'validator'
    endValidatorSpy = @spy @view.endDate, 'validator'

    @click(@doneButton.getEl()).then =>
      expect(startValidatorSpy).toHaveBeenCalledOnce()
      expect(endValidatorSpy).toHaveBeenCalledOnce()

  it 'should enable validation on change after the done button is clicked', ->
    @view.startDate.setValue('junk');

    @click(@doneButton.getEl()).then =>
      validatorSpy = @spy @view.startDate, 'validator'
      @view.startDate.setValue('2/02/2014');
      expect(validatorSpy).toHaveBeenCalledOnce()

  it 'should disable the done button when done is clicked and a date field is invalid', ->
    @view.startDate.setValue('03/01/2014');
    @click(@doneButton.getEl()).then =>
      expect(@doneButton.isDisabled()).toBe true

  it 'should enable the done button when a valid date range is selected', ->
    @view.startDate.setValue('02/02/2014');
    expect(@doneButton.isDisabled()).toBe false

  it 'should destroy the view when the done button is clicked', ->
    @click(@doneButton.getEl()).then =>
      expect(@destroySpy).toHaveBeenCalledOnce()

  it 'should fire the save event when the done button is clicked', ->
    @click(@doneButton.getEl()).then =>
      expect(@saveStub).toHaveBeenCalledWith
        startDate: @view.timelineViewModel.currentTimeframe.startDate
        endDate: @view.timelineViewModel.currentTimeframe.endDate

  it 'should destroy the view when the cancel button is clicked', ->
    @click(@cancelButton.getEl()).then =>
      expect(@destroySpy).toHaveBeenCalledOnce()

  it 'should not fire the save event when the cancel button is clicked', ->
    @click(@cancelButton.getEl()).then =>
      expect(@saveStub).not.toHaveBeenCalled()

  it 'should fire the save event when the view is destroyed and saveOnClose is true', ->
    @view.destroy()
    expect(@saveStub).toHaveBeenCalledOnce()

  it 'should not save when the view is destroyed and a validation error exists', ->
    @view.startDate.setValue('03/01/2014')
    @view.destroy()
    expect(@saveStub).not.toHaveBeenCalled()

  it 'should not fire the save event when the view is destroyed and saveOnClose is false', ->
    @view.saveOnClose = false
    @view.destroy()
    expect(@saveStub).not.toHaveBeenCalled()

  describe 'picker bounds', ->
    describe 'start date', ->
      beforeEach ->
        @triggerClickPromise = => @click(@view.startDate.triggerEl.first())

      it 'should set max date to the end date of the current timeframe', ->
        @triggerClickPromise().then =>
          expect(@view.picker.maxDate).toEqual new Date('02/28/2014')

      it 'should not set min date', ->
        @triggerClickPromise().then =>
          expect(@view.picker.minDate).toBeUndefined()

    describe 'end date', ->
      beforeEach ->
        @triggerClickPromise = => @click(@view.endDate.triggerEl.first())

      it 'should set min date to the start date of the current timeframe', ->
        @triggerClickPromise().then =>
          expect(@view.picker.minDate).toEqual new Date('02/01/2014')

      it 'should not set max date', ->
        @triggerClickPromise().then =>
          expect(@view.picker.maxDate).toBeUndefined()

  describe '#_validateDateRanges', ->

    it 'should return true if dateFields represent a valid range', ->
      @view.startDate.setValue('02/02/2014');
      @view.endDate.setValue('02/27/2014');
      expect(@view._validateDateRanges()).toBe true

    it 'should not allow the start date to be after the end date', ->
      @view.endDate.setValue('02/27/2014');
      @view.startDate.setValue('02/28/2014');
      expect(@view._validateDateRanges()).toBe 'Start date is after end date'

    it 'should not allow start date to be inside another timeframe', ->
      @view.startDate.setValue('01/31/2014');
      expect(@view._validateDateRanges()).toBe 'Date range overlaps an existing timeframe'

    it 'should not allow end date to be inside another timeframe', ->
      @view.endDate.setValue('03/01/2014');
      expect(@view._validateDateRanges()).toBe 'Date range overlaps an existing timeframe'

    it 'should not allow timeframe to completely overlap another timeframe', ->
      @view.startDate.setValue('12/31/2013');
      @view.endDate.setValue('2/28/2014');
      expect(@view._validateDateRanges()).toBe 'Date range overlaps an existing timeframe'

    it 'should not allow a non-valid start date', ->
      @view.startDate.setValue('not a date');
      expect(@view._validateDateRanges()).toBe 'Date fields must contain valid dates'

    it 'should not allow a non-valid end date', ->
      @view.endDate.setValue('not a date');
      expect(@view._validateDateRanges()).toBe 'Date fields must contain valid dates'
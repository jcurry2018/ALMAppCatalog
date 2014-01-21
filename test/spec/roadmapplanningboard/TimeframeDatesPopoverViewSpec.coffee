Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.TimeframeDatesPopoverView'
]

describe 'Rally.apps.roadmapplanningboard.TimeframeDatesPopoverView', ->
  helpers
    createTimeframe: (start, end) ->
      start: new Date(start) if start
      end: new Date(end) if end

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
      target: Ext.getBody()
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
    @click(@view.startDate.triggerEl.first()).then =>
      # be extra specific about the element we click to make Firefox happy
      @click(@view.endDate.getEl().down('input').dom).then =>
        @validPicker(@view.endDate)

  it 'should call custom validator when a date field value is changed', ->
    validatorSpy = @spy @view.startDate, 'validator'
    @view.startDate.setValue('junk');
    expect(validatorSpy).toHaveBeenCalledOnce()

  it 'should disable the done button when a validation error occurs', ->
    @view.startDate.setValue('03/01/2014');
    expect(@doneButton.isDisabled()).toBe true

  it 'should enable the done button when a valid date range is selected', ->
    @view.startDate.setValue('02/02/2014');
    expect(@doneButton.isDisabled()).toBe false

  it 'should disable the done button when you pass in invalid dates', ->
    @writeTo(@view.startDate, 'Junk').then =>
      expect(@doneButton.isDisabled()).toBe true

  it 'should destroy the view when the done button is clicked', ->
    @click(@doneButton.getEl()).then =>
      expect(@destroySpy).toHaveBeenCalledOnce()

  it 'should fire the save event when the done button is clicked', ->
    @click(@doneButton.getEl()).then =>
      expect(@saveStub).toHaveBeenCalledWith
        startDate: @view.timelineViewModel.currentTimeframe.start
        endDate: @view.timelineViewModel.currentTimeframe.end

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

      it 'should set min date to the day after the end date of the previous timeframe', ->
        @triggerClickPromise().then =>
          expect(@view.picker.minDate).toEqual new Date('02/01/2014')

      it 'should set max date to the end date of the current timeframe', ->
        @triggerClickPromise().then =>
          expect(@view.picker.maxDate).toEqual new Date('02/28/2014')

      it 'should set min date to the day after the end date of previous timeframe when start date is null', ->
        @view.timelineViewModel.currentTimeframe.start = null
        @triggerClickPromise().then =>
          expect(@view.picker.minDate).toEqual new Date('02/01/2014')

      it 'should set min date to undefined when previous time frame is null', ->
        @view.timelineViewModel.timeframes.shift()
        @triggerClickPromise().then =>
          expect(@view.picker.minDate).toBeUndefined()

    describe 'end date', ->
      beforeEach ->
        @triggerClickPromise = => @click(@view.endDate.triggerEl.first())

      it 'should set min date to the start date of the current timeframe', ->
        @triggerClickPromise().then =>
          expect(@view.picker.minDate).toEqual new Date('02/01/2014')

      it 'should set max date to the day before the start date of the next timeframe', ->
        @triggerClickPromise().then =>
          expect(@view.picker.maxDate).toEqual new Date('02/28/2014')

      it 'should set max date to the day before the start date of next timeframe when end date is null', ->
        @view.timelineViewModel.currentTimeframe.end = null
        @triggerClickPromise().then =>
          expect(@view.picker.maxDate).toEqual new Date('02/28/2014')

      it 'should set max date to undefined when next time frame is null', ->
        @view.timelineViewModel.timeframes.pop()
        @triggerClickPromise().then =>
          expect(@view.picker.maxDate).toBeUndefined()


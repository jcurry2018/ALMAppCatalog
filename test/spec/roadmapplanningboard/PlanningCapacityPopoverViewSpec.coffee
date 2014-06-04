Ext = window.Ext4 || window.Ext

describe 'Rally.apps.roadmapplanningboard.PlanningCapacityPopoverView', ->
  beforeEach ->
    @fakeModel =
      get: ->
        null
      set: ->
      save: (requester) ->

    @saveSpy = @spy @fakeModel, 'save'

    @view = Ext.create 'Rally.apps.roadmapplanningboard.PlanningCapacityPopoverView',
      target: Ext.get 'testDiv'
      model: @fakeModel

    @doneButton = @view.down('#capacityDone')
    @cancelButton = @view.down('#capacityCancel')
    @destroySpy = @spy @view, 'destroy'

  afterEach ->
    @view.destroy()

  describe 'on load', ->

    it 'should set the input values to null when the model values are null', ->
      expect(@view.lowCapacity.getValue()).toBeNull()
      expect(@view.highCapacity.getValue()).toBeNull()

  describe 'validation', ->

    it 'should not be called on change before the done button has been clicked', ->
      validatorSpy = @spy @view.lowCapacity, 'validator'
      @view.lowCapacity.setValue(213);
      expect(validatorSpy).not.toHaveBeenCalled()

    it 'should call be called on both fields when the done button is clicked', ->
      lowValidatorSpy = @spy @view.lowCapacity, 'validator'
      highValidatorSpy = @spy @view.highCapacity, 'validator'

      @click(@doneButton.getEl()).then =>
        expect(lowValidatorSpy).toHaveBeenCalledOnce()
        expect(highValidatorSpy).toHaveBeenCalledOnce()

  describe 'done button click', ->

    describe 'with an invalid range', ->

      beforeEach ->
        @view.lowCapacity.setValue(3);
        @view.highCapacity.setValue(2);
        @click(@doneButton.getEl()).then =>

      it 'should enable validation on change', ->
        validatorSpy = @spy @view.lowCapacity, 'validator'
        @view.lowCapacity.setValue(1);
        expect(validatorSpy).toHaveBeenCalledOnce()

      it 'should disable the done button', ->
        expect(@doneButton.isDisabled()).toBe true

      it 'should re-enable the done button when a valid range is entered', ->
        @view.lowCapacity.setValue(1);
        expect(@doneButton.isDisabled()).toBe false

    describe 'with a valid range', ->

      beforeEach ->
        @view.lowCapacity.setValue(2);
        @view.highCapacity.setValue(3);
        @click(@doneButton.getEl()).then =>

      it 'should destroy the view', ->
        expect(@destroySpy).toHaveBeenCalledOnce()

      it 'should save the model', ->
        expect(@saveSpy).toHaveBeenCalledOnce()

  describe 'cancel button click', ->

    beforeEach ->
      @click(@cancelButton.getEl()).then =>

    it 'should destroy the view when the cancel button is clicked', ->
      expect(@destroySpy).toHaveBeenCalledOnce()

    it 'should not fire the save event when the cancel button is clicked', ->
      expect(@saveSpy).not.toHaveBeenCalled()

  describe '#_validateRange', ->

    it 'should return true if low capacity is less than high capacity', ->
      @view.lowCapacity.setValue(1)
      @view.highCapacity.setValue(3)
      expect(@view._validateRange()).toBe true

    it 'should return true if low capacity is equal high capacity', ->
      @view.lowCapacity.setValue(3)
      @view.highCapacity.setValue(3)
      expect(@view._validateRange()).toBe true

    it 'should return false if low capacity is greater than high capacity', ->
      @view.lowCapacity.setValue(3)
      @view.highCapacity.setValue(1)
      expect(@view._validateRange()).toBe 'Low estimate should not exceed the high estimate'

    it 'should return true if values are null', ->
      @view.lowCapacity.setValue(null)
      @view.highCapacity.setValue(null)
      expect(@view._validateRange()).toBe true
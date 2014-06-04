Ext = window.Ext4 || window.Ext

Ext.require ['Rally.apps.roadmapplanningboard.util.RequestCollectionHelper']

describe 'Rally.apps.roadmapplanningboard.util.RequestCollectionHelper', ->
  helpers
    createRecords: ({oldValues, newValues, dirtyFields, dirtyCollectionFields}) ->
      field =
        name: 'field'

      model =
        getDirtyFields: -> dirtyFields || [field]
        getDirtyCollectionFields: -> dirtyCollectionFields || [field]

        modified:
          field: oldValues
        get: ->
          newValues

      return [model]

  beforeEach ->
    @RequestCollectionHelper = Rally.apps.roadmapplanningboard.util.RequestCollectionHelper

  describe '#updateRequestIfCollection', ->
    beforeEach ->
      @request = {}
      @itemAddedStub = @stub()
      @itemRemovedStub = @stub()

      @updateRequestIfCollection = => @RequestCollectionHelper.updateRequestIfCollection(
        @request, @itemAddedStub, @itemRemovedStub)

    it 'should throw an error if a collection and other fields are changed', ->
      @request.records = @createRecords
        dirtyFields: [{name: 'field'}, {name: 'field2'}]

      expect(@updateRequestIfCollection).toThrow 'Cannot update other fields on a record if a collection has changed'

    it 'should throw an error if the collection sizes are identical', ->
      @request.records = @createRecords
        oldValues: [{name: 'field'}, {name: 'field2'}]
        newValues: [{name: 'field'}, {name: 'field2'}]

      expect(@updateRequestIfCollection).toThrow 'Attempting to update a collection where nothing has changed'

    it 'should throw an error if more than relationship is removed', ->
      @request.records = @createRecords
        oldValues: [{name: 'field'}, {name: 'field2'}, {name: 'field3'}]
        newValues: [{name: 'field'}]

      expect(@updateRequestIfCollection).toThrow 'Cannot delete more than one relationship at a time'

    it 'should throw an error if more than relationship is added', ->
      @request.records = @createRecords
        oldValues: [{name: 'field'}]
        newValues: [{name: 'field'}, {name: 'field2'}, {name: 'field3'}]

      expect(@updateRequestIfCollection).toThrow 'Cannot add more than one relationship at a time'

    it 'should call onItemAddedToCollection when adding an item', ->
      @request.records = @createRecords
        oldValues: [{name: 'field'}]
        newValues: [{name: 'field'}, {name: 'field2'}]

      @updateRequestIfCollection()
      expect(@itemAddedStub).toHaveBeenCalledOnce()

    it 'should call onItemRemovedFromCollection when removing an item', ->
      @request.records = @createRecords
        oldValues: [{name: 'field'}, {name: 'field2'}]
        newValues: [{name: 'field'}]

      @updateRequestIfCollection()
      expect(@itemRemovedStub).toHaveBeenCalledOnce()

    it 'should not call onItemAddedToCollection when there are no dirty collection fields', ->
      @request.records = @createRecords
        dirtyCollectionFields: []

      @updateRequestIfCollection()
      expect(@itemRemovedStub).not.toHaveBeenCalled()

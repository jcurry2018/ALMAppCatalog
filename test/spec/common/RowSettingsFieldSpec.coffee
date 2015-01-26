Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.common.RowSettingsField'
]

describe 'Rally.apps.common.RowSettingsField', ->
  helpers
    createField: (config={}) ->
      onReady = @stub()
      @field = Ext.create 'Rally.apps.common.RowSettingsField', Ext.apply
        renderTo: 'testDiv'
        context: Rally.environment.getContext()
        value:
          showRows: true
          rowsField: 'Owner'
        explicitFields: [
          'name': 'Owner'
          'value': 'Owner'
        ]
        listeners:
          ready: onReady
      , config

      @waitForCallback onReady

  it 'should set initial value to config', ->
    @createField().then =>
      data = @field.getSubmitData()
      expect(data.showRows).toBe true
      expect(data.rowsField).toEqual 'Owner'

  it 'should not return rowsField value if not checked', ->
    @createField().then =>
      @field.down('rallycheckboxfield').setValue false
      data = @field.getSubmitData()
      expect(data.showRows).toBe false
      expect(data.rowsField).toBeUndefined()

  it 'should not return rowsField value if not selected', ->
    @createField(
      value:
        showRows: true
        rowsField: null
    ).then =>
      data = @field.getSubmitData()
      expect(data.showRows).toBe false
      expect(data.rowsField).toBeUndefined()

  it 'should include explicit rowable fields', ->
    @createField().then =>
      combobox = @field.down 'rallycombobox'
      expect(combobox.findRecordByValue('Owner')).toBeTruthy()

  it 'should sort the values in the combobox', ->
    @createField().then =>
      combobox = @field.down 'rallycombobox'
      records = combobox.getStore().getRange()
      fieldNames = _.pluck records, 'name'
      expect(fieldNames).toEqual [].concat(fieldNames).sort()

  it 'should refresh the values in the combobox', ->
    @createField(isAllowedFieldFn: (field) -> field.Name != 'Severity').then =>
      @field.refreshWithNewModelType('defect')
      @waitForEvent(@field, 'ready').then =>
        combobox = @field.down 'rallycombobox'
        expect(combobox.findRecordByValue('Severity')).toBeTruthy()

  describe 'returned fields', ->
    it 'should filter fields without attributeDefinition', ->
      @createField().then =>
        combobox = @field.down 'rallycombobox'
        expect(combobox.findRecordByValue('_refObjectName')).toBeFalsy()

    it 'should filter hidden fields', ->
      @createField().then =>
        combobox = @field.down 'rallycombobox'
        expect(combobox.findRecordByValue('Package')).toBeFalsy()

    it 'should filter non-sortable fields', ->
      @createField().then =>
        combobox = @field.down 'rallycombobox'
        expect(combobox.findRecordByValue('Milestones')).toBeFalsy()

    it 'should filter fields that do not belong to all models', ->
      @createField().then =>
        combobox = @field.down 'rallycombobox'
        expect(combobox.findRecordByValue('Milestones')).toBeFalsy()

    it 'should filter fields specified by isAllowedFieldFn', ->
      @createField(isAllowedFieldFn: (field) -> field.Name != 'Blocked').then =>
        combobox = @field.down 'rallycombobox'
        expect(combobox.findRecordByValue('Blocked')).toBeFalsy()

    it 'should filter all fields when specified by isAllowedFieldFn', ->
      @createField(isAllowedFieldFn: (field) -> false).then =>
        combobox = @field.down 'rallycombobox'
        expect(combobox.store.getCount()).toBe 1



Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.kanban.RowSettingsField'
]

describe 'Rally.apps.kanban.RowSettingsField', ->
  helpers
    createField: ->
      onReady = @stub()
      @field = Ext.create 'Rally.apps.kanban.RowSettingsField',
        renderTo: 'testDiv'
        context: Rally.environment.getContext()
        value:
          showRows: true
          rowsField: 'Owner'
        listeners:
          ready: onReady

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

  it 'should include explicit rowable fields', ->
    @createField().then =>
      combobox = @field.down 'rallycombobox'
      expect(combobox.findRecordByValue('Blocked')).toBeTruthy()
      expect(combobox.findRecordByValue('Owner')).toBeTruthy()
      expect(combobox.findRecordByValue('PlanEstimate')).toBeTruthy()
      expect(combobox.findRecordByValue('Expedite')).toBeTruthy()

  it 'should include a custom dropdown field', ->
    @createField().then =>
      combobox = @field.down 'rallycombobox'
      expect(combobox.findRecordByValue('c_KanbanState')).toBeTruthy()

  it 'should sort the values in the combobox', ->
    @createField().then =>
      combobox = @field.down 'rallycombobox'
      records = combobox.getStore().getRange()
      fieldNames = _.pluck records, 'name'
      expect(fieldNames).toEqual [].concat(fieldNames).sort()
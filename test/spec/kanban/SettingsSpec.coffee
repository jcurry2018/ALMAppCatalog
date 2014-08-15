Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.kanban.Settings'
]

describe 'Rally.apps.kanban.Settings', ->
  helpers
    getSettingsFields: (config) ->
      config = Ext.merge {
        shouldShowColumnLevelFieldPicker: false
        defaultCardFields: []
      }, config

      Rally.apps.kanban.Settings.getFields config

    getFieldByName: (fieldName, fields) ->
      return _.filter fields, (field) ->
        field.name == fieldName

  describe 'RowSettings', ->
    it 'includes row settings when configured to show', ->
      fields = @getSettingsFields shouldShowRowSettings: true
      rowField = @getFieldByName 'groupHorizontallyByField', fields
      expect(rowField.length).toBe 1

    it 'excludes row settings when configured not to show', ->
      fields = @getSettingsFields shouldShowRowSettings: false
      rowField = @getFieldByName 'groupHorizontallyByField', fields
      expect(rowField.length).toBe 0
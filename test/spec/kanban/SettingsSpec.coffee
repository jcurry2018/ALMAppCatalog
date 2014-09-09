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
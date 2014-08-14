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

    isRankInBlackList: (fields) ->
      return fields.length == 1 && fields[0]?.fieldBlackList?.indexOf('Rank') > -1

  describe 'fieldBlackList', ->
    it 'includes Rank if isDndWorkspace is not specified', ->
      fields = @getSettingsFields()
      cardFields = @getFieldByName 'cardFields', fields
      expect(@isRankInBlackList cardFields).toBe true

    it 'includes Rank if isDndWorkspace is specified as true', ->
      fields = @getSettingsFields isDndWorkspace: true
      cardFields = @getFieldByName('cardFields', fields)
      expect(@isRankInBlackList cardFields).toBe true

    it 'does not includes Rank if isDndWorkspace is specified as false', ->
      fields = @getSettingsFields isDndWorkspace: false
      cardFields = @getFieldByName('cardFields', fields)
      expect(@isRankInBlackList cardFields).toBe false

  describe 'RowSettings', ->
    it 'includes row settings when configured to show', ->
      fields = @getSettingsFields shouldShowRowSettings: true
      rowField = @getFieldByName 'groupHorizontallyByField', fields
      expect(rowField.length).toBe 1

    it 'excludes row settings when configured not to show', ->
      fields = @getSettingsFields shouldShowRowSettings: false
      rowField = @getFieldByName 'groupHorizontallyByField', fields
      expect(rowField.length).toBe 0
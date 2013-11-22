Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.kanban.Settings'
]

describe 'Rally.apps.kanban.Settings', ->
  describe 'fieldBlackList', ->
    it 'includes Rank if isDndWorkspace is not specified', ->
      fields = @_getSettingsFields()
      expect(@_isRankInBlackList(fields)).toBe true

    it 'includes Rank if isDndWorkspace is specified as true', ->
      fields = @_getSettingsFields true
      expect(@_isRankInBlackList(fields)).toBe true

    it 'does not includes Rank if isDndWorkspace is specified as false', ->
      fields = @_getSettingsFields false
      expect(@_isRankInBlackList(fields)).toBe false

  helpers
    _getSettingsFields: (isDndWorkspace) ->
      config =
        shouldShowColumnLevelFieldPicker: false
        defaultCardFields: []

      if (isDndWorkspace?)
        config.isDndWorkspace = isDndWorkspace

      Rally.apps.kanban.Settings.getFields config

    _isRankInBlackList: (fields) ->
      fieldInBlackList = false
      cardFields = _.filter(fields, (field) ->
        field.fieldLabel == 'Card Fields'
      )
      if (cardFields.length == 1 && cardFields[0]?.fieldBlackList?.indexOf('Rank') > -1)
        fieldInBlackList = true
      fieldInBlackList
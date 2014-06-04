Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.kanban.Settings'
]

describe 'Rally.apps.kanban.Settings', ->
  helpers
    getSettingsFields: (isDndWorkspace, isPageScoped) ->
      config =
        shouldShowColumnLevelFieldPicker: false
        defaultCardFields: []

      if isDndWorkspace?
        config.isDndWorkspace = isDndWorkspace
      if isPageScoped?
        config.isPageScoped = isPageScoped

      Rally.apps.kanban.Settings.getFields config

    isRankInBlackList: (fields) ->
      fieldInBlackList = false
      cardFields = _.filter(fields, (field) ->
        field.fieldLabel == 'Card Fields'
      )
      if (cardFields.length == 1 && cardFields[0]?.fieldBlackList?.indexOf('Rank') > -1)
        fieldInBlackList = true
      fieldInBlackList

  describe 'fieldBlackList', ->
    it 'includes Rank if isDndWorkspace is not specified', ->
      fields = @getSettingsFields()
      expect(@isRankInBlackList(fields)).toBe true

    it 'includes Rank if isDndWorkspace is specified as true', ->
      fields = @getSettingsFields true
      expect(@isRankInBlackList(fields)).toBe true

    it 'does not includes Rank if isDndWorkspace is specified as false', ->
      fields = @getSettingsFields false
      expect(@isRankInBlackList(fields)).toBe false

Ext = window.Ext4 || window.Ext

beforeEach ->
  @addMatchers
    toHaveSetting: (type) ->
      @message = -> "Expected App to#{if @isNot then ' not' else ''} have setting of type #{type}"
      settingsTypes = _.pluck @actual.getSettingsFields(), 'type'
      _.contains settingsTypes, type
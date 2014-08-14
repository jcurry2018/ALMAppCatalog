Ext = window.Ext4 || window.Ext

describe 'Rally.apps.teamboard.TeamBoardColumn', ->
  beforeEach ->
    @cardboardHelper = Rally.test.helpers.CardBoard
  helpers
    createColumn: (config) ->
      @ajax.whenQuerying('iteration').respondWith()
      @ajax.whenQuerying('user').respondWith()

      @column = @cardboardHelper.createColumn(Ext.apply(
        columnClass: 'Rally.apps.teamboard.TeamBoardColumn'
        attribute: 'TeamMemberships'
        contentCell: Ext.get('testDiv')
        headerCell: Ext.get('testDiv')
        model: 'User'
        renderTo: 'testDiv'
        value: '/project/123'
      , config)
      )

      @waitForComponentReady @column

  afterEach ->
    @column.destroy()

  it 'should use TeamBoardDropController', ->
    @createColumn().then =>
      expect(_.find @column.plugins, (plugin) -> plugin.ptype == 'rallyteamboarddropcontroller').not.toBeUndefined()

  describe 'iteration combo', ->
    helpers
      iterationCombo: ->
        @column.getColumnHeader().down 'rallyiterationcombobox'

    it 'should be in the header', ->
      @createColumn().then =>
        expect(@iterationCombo()).not.toBeNull()

    it 'should only have iterations for the team', ->
      @createColumn().then =>
        expect(@iterationCombo().storeConfig.context.project).toBe '/project/123'
        expect(@iterationCombo().storeConfig.context.projectScopeUp).toBe false
        expect(@iterationCombo().storeConfig.context.projectScopeDown).toBe false

    it 'should publish iterationcomboready', ->
      iterationComboReady = @spy()
      @createColumn(
        listeners:
          iterationcomboready: iterationComboReady
      ).then ->
        expect(iterationComboReady).toHaveBeenCalledOnce()
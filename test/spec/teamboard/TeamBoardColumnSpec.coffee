Ext = window.Ext4 || window.Ext

Ext.require ['Rally.apps.teamboard.TeamBoardCard']

describe 'Rally.apps.teamboard.TeamBoardColumn', ->
  beforeEach ->
    @cardboardHelper = Rally.test.helpers.CardBoard
  helpers
    createColumn: (config) ->
      @column = @cardboardHelper.createColumn Ext.apply
        attribute: 'TeamMemberships'
        cardConfig:
          xtype: 'rallyteamboardcard'
        columnClass: 'Rally.apps.teamboard.TeamBoardColumn'
        contentCell: Ext.get('testDiv')
        headerCell: Ext.get('testDiv')
        model: 'User'
        renderTo: 'testDiv'
        value: '/project/123'
      , config

      @waitForComponentReady @column

  beforeEach ->
    @ajax.whenQuerying('iteration').respondWith()
    @ajax.whenQuerying('user').respondWith()

  afterEach ->
    @column.destroy()

  it 'should use TeamBoardDropController', ->
    @createColumn().then =>
      expect(_.find @column.plugins, (plugin) -> plugin.ptype == 'rallyteamboarddropcontroller').not.toBeUndefined()

  describe 'sorting', ->
    helpers
      assertCardsInOrder: (firstNames) ->
        expect(_.map @column.getRecords(), (record) -> record.get('FirstName')).toEqual firstNames

    beforeEach ->
      userData = @mom.getData 'User', count: 7

      modifyUserData = (role, firstName, userData) ->
        userData.Role = role
        userData.FirstName = firstName
      modifyUserData 'None', 'Larry', userData[0]
      modifyUserData 'Developer', 'Tom', userData[1]
      modifyUserData 'Developer', 'Bob', userData[2]
      modifyUserData 'Developer', 'Fred', userData[3]
      modifyUserData '', 'Jon', userData[4]
      modifyUserData 'Product Owner', 'Monica', userData[5]
      modifyUserData 'Team Lead', 'Joe', userData[6]

      @ajax.whenQuerying('user').respondWith userData

    it 'should be by default sort when groupBy not specified', ->
      @createColumn(
        storeConfig:
          sorters: [{direction: 'ASC', property: 'FirstName'}]
      ).then =>
        @assertCardsInOrder ['Bob', 'Fred', 'Joe', 'Jon', 'Larry', 'Monica', 'Tom']

    describe 'when groupBy is specified', ->
      it 'should be by groupBy field frequency (None and blanks last) then groupBy field name then first name', ->
        @createColumn(groupBy: 'Role').then =>
          @assertCardsInOrder ['Monica', 'Joe', 'Bob', 'Fred', 'Tom', 'Jon', 'Larry']

      it 'should fetch groupBy field', ->
        @createColumn(groupBy: 'OfficeLocation').then =>
          expect(@column.getAllFetchFields()).toContain 'OfficeLocation'

      it 'should be able to later add a card from a new group', ->
        @createColumn(groupBy: 'Role').then =>
          record = @mom.getRecord 'User',
            values:
              FirstName: 'NewGuy'
              Role: 'NewRole'
          @column.createAndAddCard record

          @assertCardsInOrder ['NewGuy', 'Monica', 'Joe', 'Bob', 'Fred', 'Tom', 'Jon', 'Larry']

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

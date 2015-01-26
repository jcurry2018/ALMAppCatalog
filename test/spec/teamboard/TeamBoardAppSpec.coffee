Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.teamboard.TeamBoardProjectRecordsLoader'
]

describe 'Rally.apps.teamboard.TeamBoardApp', ->
  helpers
    cardboard: ->
      @app.down('.rallycardboard')

    createApp: (options = {}) ->
      @stubIsAdmin if options.isAdmin? then options.isAdmin else true
      @stubProjectRecords options.projectRecords || [@projectRecord]

      @app = Ext.create 'Rally.apps.teamboard.TeamBoardApp', Ext.apply(
        context: Ext.create 'Rally.app.Context'
        renderTo: 'testDiv'
      , options.appConfig)

      @waitForComponentReady @app

    stubIsAdmin: (isAdmin) ->
      @stub(Rally.environment.getContext().getPermissions(), 'isWorkspaceOrSubscriptionAdmin').returns isAdmin

    stubProjectRecords: (projectRecords) ->
      @stub Rally.apps.teamboard.TeamBoardProjectRecordsLoader, 'load', (teamOids, callback, scope) ->
        callback.call scope, projectRecords

  beforeEach ->
    @ajax.whenQuerying('user').respondWith @mom.getData('user')

    @projectRecord = @mom.getRecord 'project'

  afterEach ->
    @app?.destroy()

  it 'should show a message when user does not have access to any of the teams chosen', ->
    @createApp(projectRecords: []).then =>
      expect(@app.getEl().down('.no-data')).not.toBe null

  it 'should show a board with one column per team', ->
    @createApp(projectRecords: @mom.getRecords 'project', count: 4).then =>
      expect(@cardboard().columns.length).toBe 4

  it 'should show non-disabled team members in each column', ->
    @createApp().then =>
      expect(@cardboard().getColumns()[0].store).toOnlyHaveFilters [
        ['TeamMemberships', 'contains', @projectRecord.get('_ref')]
        ['Disabled', '=', 'false']
      ]

  it 'should create a readOnly board when current user is not an admin', ->
    @createApp(isAdmin: false).then =>
      expect(@cardboard().readOnly).toBe true

  it 'should create a drag-n-drop-able board when current user is an admin', ->
    @createApp(isAdmin: true).then =>
      expect(@cardboard().readOnly).toBe false

  it 'should show the team name in the column header', ->
    @createApp().then =>
      headerHtml = @cardboard().getColumns()[0].getHeaderTitle().getEl().down('.columnTpl').getHTML()
      Assert.contains headerHtml, @projectRecord.get('_refObjectName')

  describe 'settings', ->
    helpers
      createAppWithSettings: (settings = {}) ->
        @createApp
          appConfig:
            settings: settings

    describe 'card fields', ->
      helpers
        assertFieldsShownOnCard: (fieldNames) ->
          cardEl = @cardboard().getColumns()[0].getCards()[0].getEl()

          expect(cardEl.query('.rui-card-content > .field-content').length).toBe fieldNames.length

          for fieldName in fieldNames
            expect(cardEl.down('.field-content.' + fieldName)).not.toBeNull()

      it 'should be OfficeLocation and Phone by default', ->
        @createAppWithSettings().then =>
          @assertFieldsShownOnCard ['OfficeLocation', 'Phone']

      it 'should allow no fields to be shown', ->
        @createAppWithSettings(cardFields: null).then =>
          @assertFieldsShownOnCard []

      it 'should be the chosen card fields', ->
        @createAppWithSettings(cardFields: 'EmailAddress,OnpremLdapUsername').then =>
          @assertFieldsShownOnCard ['EmailAddress', 'OnpremLdapUsername']

    describe 'group by', ->
      helpers
        assertGroupByIs: (groupBy) ->
          column = @cardboard().getColumns()[0]
          expect(column.groupBy).toBe groupBy
          expect(column.getCards()[0].groupBy).toBe groupBy

      it 'should be Role by default', ->
        @createAppWithSettings().then =>
          @assertGroupByIs 'Role'

      it 'should allow no group by', ->
        @createAppWithSettings(groupBy: null).then =>
          @assertGroupByIs undefined

      it 'should be the chosen group by', ->
        @createAppWithSettings(groupBy: 'Department').then =>
          @assertGroupByIs 'Department'

      it 'should not group if field does not exist on User model (may occur if field has been renamed)', ->
        @createAppWithSettings(groupBy: 'CustomField').then =>
          @assertGroupByIs undefined

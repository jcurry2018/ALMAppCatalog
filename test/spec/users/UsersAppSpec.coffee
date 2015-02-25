Ext = window.Ext4 || window.Ext

describe 'Rally.apps.users.UsersApp', ->
  beforeEach ->
    @ajax.whenQuerying('typedefinition').respondWith [Rally.test.mock.data.WsapiModelFactory.getModelDefinition('User')]

    @ajax.whenQuerying('User').respondWith @mom.getData('User')

    @workspaces = @mom.getData 'Workspace', values: WorkspaceConfiguration: {}
    @ajax.whenQueryingEndpoint('workspaces/admin').respondWith @workspaces

    @ajax.whenQueryingEndpoint('/licensing/seats.sp').respondWith {}

    @app = Ext.create 'Rally.apps.users.UsersApp',
      context: Ext.create 'Rally.app.Context',
        initialValues:
          workspace: Rally.environment.getContext().getWorkspace()
      height: 1000
      renderTo: 'testDiv'

    @waitForComponentReady @app

  it 'should create the application', ->
    expect(@app).not.toBeNull()

  it 'should have a count of subscription seats as the last item in the left header', ->
    expect(@app.gridboard.getHeader().getLeft().items.last().xtype).toBe 'rallysubscriptionseats'

  it 'should apply custom filter config', ->
    customFilterPluginConfig = _.find(@app.getGridBoardPlugins(), { ptype:'rallygridboardcustomfiltercontrol'})
    expect(customFilterPluginConfig.showUserFilter).toBe true

  describe 'workspace filter', ->
    it 'should not filter by workspace by default', ->
      expect(@app.gridboard.getGridOrBoard().store).toHaveNoFilters()

    it 'should filter by workspace when one is selected', ->
      new Helpers.ComboBoxHelper('.user-workspace-picker').openAndSelect(@workspaces[0]._refObjectName).then =>
        expect(@app.context.getWorkspace().ObjectID).toBe @workspaces[0].ObjectID
        expect(@app.gridboard.getGridOrBoard().store).toOnlyHaveFilter ['WorkspacePermission', '!=', 'No Access']

    it 'should be to the right of the filter control', ->
      headerItemIds = _.pluck @app.gridboard.getHeader().getLeft().items.getRange(), 'itemId'
      expect(headerItemIds.indexOf('gridBoardFilterControlCt')).toBe headerItemIds.indexOf('userWorkspacePicker') - 1

  describe '#getScopedStateId', ->
    it 'should include user scoping', ->
      expect(@app.getScopedStateId()).toContain 'user'

    it 'should not include workspace scoping', ->
      expect(@app.getScopedStateId()).not.toContain 'workspace'

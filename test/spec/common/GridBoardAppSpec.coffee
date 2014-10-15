Ext = window.Ext4 || window.Ext

describe 'Rally.apps.common.GridBoardApp', ->
  helpers
    createApp: (config = {}) ->
      sub = Rally.environment.getContext().getSubscription()
      sub.Modules[0] = 'Rally Portfolio Manager'
      @app = Ext.create 'Rally.apps.common.GridBoardApp', _.merge(
        modelNames: ['hierarchicalrequirement']
        columnNames: ['FormattedID', 'Name']
        context: Ext.create 'Rally.app.Context',
          initialValues:
            project: Rally.environment.getContext().getProject()
            workspace: Rally.environment.getContext().getWorkspace()
            user: Rally.environment.getContext().getUser()
            subscription: sub
        renderTo: 'testDiv'
      , config)
      @waitForComponentReady @app

  beforeEach ->
    @ajax.whenQuerying('project').respondWith [_ref: '/project/123']

  describe 'component rendering ', ->
    it 'should show an Add New button when enableAddNew is true', ->
      @createApp(enableAddNew: true).then =>
        expect(Ext.query('.add-new a.new').length).toBe 1

    it 'should not show an Add New button when enableAddNew is false', ->
      @createApp(enableAddNew: false).then =>
        expect(Ext.query('.add-new a.new').length).toBe 0

    it 'should not show an Add New button without proper permissions', ->
      @stub Rally.environment.getContext().getPermissions(), 'isProjectEditor', -> false
      @createApp(enableAddNew: true).then =>
        expect(Ext.query('.add-new a.new').length).toBe 0

    it 'should show a filter button when enableFilterControl is true', ->
      @createApp(enableFilterControl: true).then =>
        expect(Ext.query('.gridboard-filter-control').length).toBe 1

    it 'should not show a filter button when enableFilterControl is false', ->
      @createApp(enableFilterControl: false).then =>
        expect(Ext.query('.gridboard-filter-control').length).toBe 0

    it 'should show an owner filter when enableOwnerFilter is true', ->
      @createApp(enableOwnerFilter: true).then =>
        expect(Ext.query('.rally-owner-filter').length).toBe 1

    it 'should not show an owner filter when enableOwnerFilter is false', ->
      @createApp(enableOwnerFilter: false).then =>
        expect(Ext.query('.rally-owner-filter').length).toBe 0

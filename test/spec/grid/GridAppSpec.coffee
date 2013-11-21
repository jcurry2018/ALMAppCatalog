Ext = window.Ext4 || window.Ext
describe 'Rally.apps.grid.GridApp', ->

  helpers
    createApp: (config) ->
      @app = Ext.create 'Rally.apps.grid.GridApp', Ext.apply
        context: Ext.create 'Rally.app.Context',
          initialValues:
            project:
              _ref: '/project/1'
            objectType: 'userstory'
        renderTo: 'testDiv'
      , config

      @once condition: => @app.down 'rallygrid'

  beforeEach ->
    @ajax.whenQuerying('userstory').respondWith []

  afterEach ->
    @app?.destroy()

  it 'passes the current context to the grid', ->
    @createApp().then =>
      expect(@app.down('rallygrid').getContext()).toBe @app.getContext()
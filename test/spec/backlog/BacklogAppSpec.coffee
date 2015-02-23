Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.backlog.BacklogApp',
]

describe 'Rally.apps.backlog.BacklogApp', ->
  helpers
    createApp: (options = {}) ->
      @app = Ext.create 'Rally.apps.backlog.BacklogApp',
        context: @_getContext()
        renderTo: options.renderTo || 'testDiv'
        height: 400

      @once(condition: => @app.down('rallygridboard'))

    _getContext: (context) ->
      Ext.create('Rally.app.Context',
        initialValues: Ext.apply(
          project:
            _ref: '/project/1'
            Name: 'Project 1'
          workspace:
            WorkspaceConfiguration:
              DragDropRankingEnabled: true
        , context)
      )

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'backlogapp'

  it 'should apply custom filter config', ->
    @createApp().then =>
      customFilterPluginConfig = _.find(@app.getGridBoardPlugins(), { ptype:'rallygridboardcustomfiltercontrol'})
      expect(customFilterPluginConfig.showIdFilter).toBe true
      expect(customFilterPluginConfig.showOwnerFilter).toBe false
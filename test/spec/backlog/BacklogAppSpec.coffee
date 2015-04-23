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

      @once(condition: => @app.down('rallygridboard')).then =>
        @grid = @app.gridboard.getGridOrBoard()

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

  beforeEach ->
    @ajax.whenQuerying('artifact').respondWith(@mom.getData('hierarchicalrequirement', count: 5))

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'backlogapp'

  it 'should apply custom filter config', ->
    @createApp().then =>
      customFilterPluginConfig = _.find(@app.getGridBoardPlugins(), { ptype:'rallygridboardcustomfiltercontrol'})
      expect(customFilterPluginConfig.showIdFilter).toBe true
      expect(customFilterPluginConfig.showOwnerFilter).toBe false

  it 'should set unscheduled Iteration on inline add new', ->
    createStub = @stub()
    Rally.environment.getMessageBus().subscribe Rally.nav.Message.create, createStub
    @createApp().then =>
      @grid.view.fireEvent('inlineadd', @grid.view, @grid.store.getRootNode().childNodes[0], {action: 'inlineaddpeer'})
      @once(condition: => Ext.ComponentQuery.query('rallyinlineaddnew')[0]).then (inlineAddNew) =>
        @click(inlineAddNew.down('#addWithDetails').el.dom).then =>
          expect(createStub.lastCall.args[1].Iteration).toBe 'u'

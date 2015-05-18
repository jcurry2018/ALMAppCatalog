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
      peer =  @grid.store.getRootNode().childNodes[0]
      peer.set('Iteration', undefined);
      @grid.view.fireEvent('inlineadd', @grid.view, peer, {action: 'inlineaddpeer'})
      @once(condition: => Ext.ComponentQuery.query('rallyinlineaddnew')[0]).then (inlineAddNew) =>
        @click(inlineAddNew.down('#addWithDetails').el.dom).then =>
          expect(createStub.lastCall.args[1].Iteration).toBe 'u'

  describe '#getPermanentFilters', ->
    helpers
      expectFiltersForTypes: (types) ->
        @createApp().then =>
          filters = @app.getPermanentFilters types
          expect(filters.length).toEqual 2

          query = filters[1].toString()

          if _.contains(types, 'hierarchicalrequirement')
            expect(query).toContain('(DirectChildrenCount = 0) AND (TypeDefOid = 12416)')

          if _.contains(types, 'defect')
            expect(query).toContain('(State != "Closed") AND (TypeDefOid = 12476)')

          if _.contains(types, 'defectSuite')
            expect(query).toContain('(TypeDefOid = 12481)')

    it 'should return filters for all types if no types are given', ->
      @expectFiltersForTypes()

    it 'should return filters for all types if all types are given', ->
      @expectFiltersForTypes ['hierarchicalrequirement', 'defect', 'defectSuite']

    it 'should return filters for just defects', ->
      @expectFiltersForTypes ['defect']

    it 'should return filters for just defectsuites', ->
      @expectFiltersForTypes ['defectSuite']

    it 'should return filters for just user stories', ->
      @expectFiltersForTypes ['hierarchicalrequirement']

    it 'should return filters for defects and user stories', ->
      @expectFiltersForTypes ['hierarchicalrequirement', 'defect']

    it 'should return filters for defects and defect suites', ->
      @expectFiltersForTypes ['defect', 'defectSuite']

    it 'should return filters for user stories and defect suites', ->
      @expectFiltersForTypes ['hierarchicalrequirement', 'defectSuite']

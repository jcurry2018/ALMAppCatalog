Ext = window.Ext4 || window.Ext
describe 'Rally.apps.grid.GridApp', ->

  helpers
    createApp: (config, contextValues) ->
      @app = Ext.create 'Rally.apps.grid.GridApp', Ext.apply
        context: Ext.create 'Rally.app.Context',
          initialValues: Ext.apply
            project:
              _ref: '/project/1'
            user:
              _ref: '/user/2'
          , contextValues
        renderTo: 'testDiv'
      , config

      @once condition: => @grid = @app.down 'rallygrid'

    createTimeboxScopedApp: (config) ->
      @createApp config, timebox: @mom.getRecord 'iteration'

  beforeEach ->
    @ajax.whenQuerying('userstory').respondWith []

  afterEach ->
    @app?.destroy()

  it 'passes the current context to the grid', ->
    @createApp().then =>
      expect(@app.down('rallygrid').getContext()).toBe @app.getContext()

  it 'passes the types to the grid', ->
    @createApp(
      settings:
        types: 'userstory,defect'
    ).then =>
      expect(@grid.storeConfig.models).toEqual ['userstory', 'defect']

  it 'passes the page size to the grid', ->
    @createApp(
      settings:
        pageSize: 100
    ).then =>
      expect(@grid.storeConfig.pageSize).toBe 100
      expect(@grid.pagingToolbarCfg.pageSizes).toEqual [100]

  it 'passes the columns to the grid', ->
    @createApp(
      settings:
        fetch: 'FormattedID,Name,Owner,Project'
    ).then =>
      expect(@grid.columnCfgs).toEqual @app.settings.fetch.split(',')
      expect(@grid.storeConfig.fetch).toBe @app.settings.fetch

  it 'passes the sort order to the grid', ->
    @createApp(
      settings:
        order: 'Name ASC'
    ).then =>
      sorters = @grid.storeConfig.sorters
      expect(sorters.length).toBe 1
      expect(sorters[0].property).toBe 'Name'
      expect(sorters[0].direction).toBe 'ASC'

  it 'passes the query to the grid', ->
    @createApp(
      settings:
        query: '(Name contains foo)'
    ).then =>
      filters = @grid.storeConfig.filters
      expect(filters.length).toBe 1
      expect(filters[0].toString()).toBe Rally.data.wsapi.Filter.fromQueryString(@app.settings.query).toString()

  it 'passes the user query to the grid on a timebox filtered dashboard', ->
    @createTimeboxScopedApp(
      settings:
        query: '(Name contains foo)'
    ).then =>
      filters = @grid.storeConfig.filters
      expect(filters.length).toBe 2
      expect(filters[0].toString()).toBe Rally.data.wsapi.Filter.fromQueryString(@app.settings.query).toString()
      expect(filters[1].toString()).toBe @app.getContext().getTimeboxScope().getQueryFilter().toString()

  it 'passes the query to the grid on a timebox filtered dashboard with no user query', ->
    @createTimeboxScopedApp().then =>
      filters = @grid.storeConfig.filters
      expect(filters.length).toBe 1
      expect(filters[0].toString()).toBe @app.getContext().getTimeboxScope().getQueryFilter().toString()

  it 'passes the timebox query when all types are schedulable', ->
    @createTimeboxScopedApp(
      settings:
        types: 'hierarchicalrequirement,task,defect,defectsuite,testset'
    ).then =>
      filters = @grid.storeConfig.filters
      expect(filters.length).toBe 1
      expect(filters[0].toString()).toBe @app.getContext().getTimeboxScope().getQueryFilter().toString()

  it 'does not pass the timebox query when all types are not schedulable', ->
    @createTimeboxScopedApp(
      settings:
        types: 'user'
    ).then =>
      expect(@grid.storeConfig.filters.length).toBe 0

  it 'should interpolate context variables into the query', ->
    @createApp(
      settings:
        query: '(Owner = {user})'
    ).then =>
      filters = @grid.storeConfig.filters
      expect(filters.length).toBe 1
      expect(filters[0].toString()).toBe Rally.data.wsapi.Filter.fromQueryString(
        "(Owner = #{Rally.util.Ref.getRelativeUri(@app.getContext().getUser())})"
      ).toString()

  it 'refreshes the grid when the timebox scope changes', ->
    @createTimeboxScopedApp().then =>
      newTimeboxScope = Ext.create 'Rally.app.TimeboxScope', record: @mom.getRecord 'iteration'
      filterSpy = @spy @grid, 'filter'
      @app.onTimeboxScopeChange newTimeboxScope
      expect(@app.getContext().getTimeboxScope().getRecord()).toBe newTimeboxScope.getRecord()
      expect(filterSpy).toHaveBeenCalledOnce()
      args = filterSpy.firstCall.args
      expect(args[0].length).toBe 1
      expect(args[0][0].toString()).toBe newTimeboxScope.getQueryFilter().toString()
      expect(args[1]).toBe true
      expect(args[2]).toBe true


  describe 'build query does not execute user-entered code', ->
    beforeEach ->
      window.__hacked_by_test_buildQueryDoesNotExecuteUserEnteredCode = false
    afterEach ->
      delete window.__hacked_by_test_buildQueryDoesNotExecuteUserEnteredCode

    it 'does not execute code', ->
      @createApp(
        settings:
          query: '(Owner = {[window.__hacked_by_test_buildQueryDoesNotExecuteUserEnteredCode=true]})'
      ).then =>
        expect(window.__hacked_by_test_buildQueryDoesNotExecuteUserEnteredCode).toBe false

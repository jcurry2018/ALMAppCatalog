Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.app.Context'
  'Rally.apps.defectsuites.DefectSuitesApp'
]

describe 'Rally.apps.defectsuites.DefectSuitesApp', ->
  helpers
    createApp: ->
      @app = Ext.create 'Rally.apps.defectsuites.DefectSuitesApp',
        context: Ext.create 'Rally.app.Context',
          initialValues:
            permissions: Rally.environment.getContext().getPermissions()
            project: Rally.environment.getContext().getProject()
            subscription: Rally.environment.getContext().getSubscription()
            user: Rally.environment.getContext().getUser()
            workspace: Rally.environment.getContext().getWorkspace()
        renderTo: 'testDiv'
        height: 400
      @waitForComponentReady @app

    stubFeatureToggle: (toggles, value = true) ->
      stub = @stub(Rally.app.Context.prototype, 'isFeatureEnabled');
      stub.withArgs(toggle).returns(value) for toggle in toggles
      stub

  beforeEach ->
    @ajax.whenQuerying('artifact').respondWith(@mom.getData('defectsuite', count: 5))

  afterEach ->
    @app?.destroy()

  describe 'filtering panel plugin', ->
    helpers
      getPlugin: (filterptype='rallygridboardinlinefiltercontrol') ->
        gridBoard = @app.down 'rallygridboard'
        _.find gridBoard.plugins, (plugin) ->
          plugin.ptype == filterptype

    it 'should have the old filter component by default', ->
      @createApp().then =>
        expect(@getPlugin('rallygridboardcustomfiltercontrol')).toBeDefined()

    it 'should use rallygridboard filtering plugin', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp().then =>
        expect(@getPlugin()).toBeDefined()

  describe 'shared view plugin', ->
    helpers
      getPlugin: (filterptype='rallygridboardsharedviewcontrol') ->
        gridBoard = @app.down 'rallygridboard'
        _.find gridBoard.plugins, (plugin) ->
          plugin.ptype == filterptype

    it 'should not have shared view plugin if the toggle is off', ->
      @createApp().then =>
        expect(@getPlugin()).not.toBeDefined()

    it 'should use rallygridboard shared view plugin if toggled on', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp().then =>
        plugin = @getPlugin()
        expect(plugin).toBeDefined()
        expect(plugin.sharedViewConfig.stateful).toBe true
        expect(plugin.sharedViewConfig.stateId).toBe @app.getContext().getScopedStateId('defect-suites-shared-view')

    it 'sets current view on viewchange', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp().then =>
        loadSpy = @spy(@app, 'loadGridBoard')
        @app.gridboard.fireEvent 'viewchange'
        expect(loadSpy).toHaveBeenCalledOnce()
        expect(@app.down('#gridBoard')).toBeDefined()

    it 'contains default view', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp().then =>
        plugin = @getPlugin()
        expect(plugin.controlCmp.defaultViews.length).toBe 1
        expect(plugin.controlCmp.defaultViews[0].Name).toBe 'Default View'

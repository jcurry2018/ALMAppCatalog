Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp',
  'Ext.state.Manager',
  'Rally.data.util.PortfolioItemTypeDefList'
]

describe 'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', ->

  helpers
    createApp: (enableToggles) ->
      context = Ext.create 'Rally.app.Context',
        initialValues:
          project: Rally.environment.getContext().getProject()
          workspace: Rally.environment.getContext().getWorkspace()
          user: Rally.environment.getContext().getUser()
          subscription: Rally.environment.getContext().getSubscription()

      context.isFeatureEnabled = -> enableToggles

      Ext.create 'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp',
        context: context
        renderTo: 'testDiv'

    renderApp: (enableToggles = true) ->
      @app = @createApp(enableToggles)
      @waitForComponentReady @app

  beforeEach ->
    @piHelper = new Helpers.PortfolioItemGridBoardHelper @
    @piHelper.stubPortfolioItemRequests()

  afterEach ->
    _.invoke Ext.ComponentQuery.query('portfoliotemstreegridapp'), 'destroy'

  it 'should initialize', ->
    @renderApp().then =>
      expect(Ext.isDefined(@app)).toBe true

  it 'should use the row expansion plugin', ->
    @renderApp().then =>
      plugins = _.map @app.gridboard.gridConfig.plugins, (plugin) -> plugin.ptype || plugin
      expect(plugins).toContain 'rallytreegridexpandedrowpersistence'

  it 'should configure the tree store to the portfolio item types', ->
    @renderApp().then =>
      storeTypes = _.pluck(@app.gridboard.gridConfig.store.models, 'elementName')
      piTypes = _.pluck(@piTypes, 'Name')
      expect(_.intersection(storeTypes, piTypes)).toEqual piTypes

  describe '#getGridConfig', ->
    it 'should return bufferedRenderer true when feature toggle enabled', ->
      @renderApp(true).then =>
        expect(@app.getGridConfig().bufferedRenderer).toBe true

    it 'should return bufferedRenderer false when feature toggle disabled', ->
      @renderApp(false).then =>
        expect(@app.getGridConfig().bufferedRenderer).toBe false

    it 'should enable inline add when feature toggle enabled', ->
      @renderApp(true).then =>
        expect(@app.getGridConfig().enableInlineAdd).toBe true

    it 'should disable inline add when feature toggle disabled', ->
      @renderApp(false).then =>
        expect(@app.getGridConfig().enableInlineAdd).toBe false

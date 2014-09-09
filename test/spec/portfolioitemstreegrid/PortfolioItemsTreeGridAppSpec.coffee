Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp',
  'Ext.state.Manager',
  'Rally.data.util.PortfolioItemTypeDefList'
]

describe 'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', ->

  helpers
    createApp: ->
      context = Ext.create 'Rally.app.Context',
        initialValues:
          project: Rally.environment.getContext().getProject()
          workspace: Rally.environment.getContext().getWorkspace()
          user: Rally.environment.getContext().getUser()
          subscription: Rally.environment.getContext().getSubscription()

      context.isFeatureEnabled = -> true

      Ext.create 'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp',
        context: context
        renderTo: 'testDiv'


    renderApp: ->
      @app = @createApp()
      @waitForComponentReady @app

  beforeEach ->
    Rally.environment.getContext().context.subscription.Modules = ['Rally Portfolio Manager']

    @theme = Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemTheme')
    @initiative = Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemInitiative')
    @feature = Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemFeature')

    @piTypes = [
      @theme
      @initiative
      @feature
    ]

    @typeRequest = @ajax.whenQuerying('typedefinition').respondWith @piTypes

    @stub Rally.data.util.PortfolioItemTypeDefList::, 'getArray', =>
      Deft.Promise.when @piTypes

    @stub Rally.data.TypeDefinitionFetcher::, 'fetchTypeDefinitions', =>
      Deft.Promise.when Results: @piTypes

    theme = @mom.getRecord('PortfolioItem/Theme')
    @ajax.whenQuerying('PortfolioItem/Theme ').respondWith [theme.data]
    initiative = @mom.getRecord('PortfolioItem/Initiative')
    @ajax.whenQuerying('PortfolioItem/Initiative').respondWith [initiative.data]
    feature = @mom.getRecord('PortfolioItem/Feature')
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith [feature.data]
    @ajax.whenQuerying('artifact').respondWith()

  afterEach ->
    _.invoke Ext.ComponentQuery.query('portfoliotemstreegridapp'), 'destroy'

  it 'should initialize', ->
    @renderApp().then =>
      expect(Ext.isDefined(@app)).toBeTruthy()

  it 'should use the row expansion plugin', ->
    @renderApp().then =>
      plugins = @app.gridboard.gridConfig.plugins
      expect(_.find(plugins, ptype: 'rallytreegridexpandedrowpersistence')).toBeTruthy()

  it 'should configure the tree store to the portfolio item types', ->
    @renderApp().then =>
      storeTypes = _.pluck(@app.gridboard.gridConfig.store.models, 'elementName')
      piTypes = _.pluck(@piTypes, 'Name')
      expect(_.intersection(storeTypes, piTypes)).toEqual piTypes

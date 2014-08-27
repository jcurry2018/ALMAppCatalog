Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp',
  'Ext.state.Manager',
  'Rally.data.util.PortfolioItemTypeDefList'
]

describe 'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', ->

  helpers
    getPiTreeGridAppConfig: (featureEnabled) ->
      defaultSettings:
        modelNames: ['PortfolioItem/Project']
      getHeight: -> 250
      getContext: ->
        get: ->
        isFeatureEnabled: -> featureEnabled
        getScopedStateId: -> 'someStateId'
        getDataContext: ->
          project: true
        getWorkspace: ->
          WorkspaceConfiguration:
            DragDropRankingEnabled: true

  beforeEach ->
    @ajax.whenQuerying('artifact').respondWith()

  afterEach ->
    _.invoke Ext.ComponentQuery.query('portfoliotemstreegridapp'), 'destroy'

  it 'should initialize', ->
    piTreeGridApp = Ext.create 'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', @getPiTreeGridAppConfig(false)
    expect(Ext.isDefined(piTreeGridApp)).toBeTruthy()


  it 'should add the PI type picker plugin', ->
    @stub(Ext.state.Manager, 'get').returns null
    appCfg = _.extend(@getPiTreeGridAppConfig(true), {modelNames: 'PortfolioItem/Project'})
    piTreeGridApp = Ext.create 'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', appCfg
#   Yes I'm calling a testing private method. Multiple cases of inline creation of classes that return promises rendered us incapable of writing a better test.
    gridPlugins = piTreeGridApp._getGridBoardPlugins()

    expect(gridPlugins).not.toBeNull
    expect(gridPlugins.length).toBeGreaterThan 0
    expect(_.find(gridPlugins, (plugin)->
      plugin.ptype == 'rallygridboardpitypecombobox')).toBeTruthy()

  it 'should have filter configuration using lowest-level PI type', ->
    @stub(Ext.state.Manager, 'get').returns null
    appCfg = _.extend(@getPiTreeGridAppConfig(true), {modelNames: 'PortfolioItem/Project'})
    piTreeGridApp = Ext.create 'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', appCfg

    @stub Rally.data.util.PortfolioItemTypeDefList::, 'getArray', ->
      Deft.Promise.when [
        {TypePath: 'CindyCrawford'},
        {TypePath: 'HeidiKlum'},
        {TypePath: 'ElleMcPherson'}
      ]
    piTreeGridApp.fireEvent('afterrender')
    piTreeGridApp.launch()

    filterConfig = piTreeGridApp.filterControlConfig
    expect(filterConfig.modelNames).toEqual(['CindyCrawford'])

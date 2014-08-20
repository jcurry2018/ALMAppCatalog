Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.treegrid.TreeGridApp'
]

describe 'Rally.apps.treegrid.TreeGridApp', ->

  helpers
    getTreeGridAppConfig: (featureEnabled) ->
      defaultSettings:
        modelNames: ['PortfolioItem/Initiative']
      getHeight: -> 250
      getContext: ->
        get: ->
        isFeatureEnabled: -> featureEnabled
        getScopedStateId: -> 'someStateId'
        getWorkspace: ->
          WorkspaceConfiguration:
            DragDropRankingEnabled: true

    createTreeGridApp: (config) ->
      appCfg = _.extend(@getTreeGridAppConfig(true), config || {})

      treeGridApp = Ext.create 'Rally.apps.treegrid.TreeGridApp', appCfg
      treeGridApp.fireEvent('afterrender')
      treeGridApp

  beforeEach ->
    @ajax.whenReading("project", 431439).respondWith _ref: "/project/431439"
    @ajax.whenQueryingEndpoint('schema').respondWith Rally.test.mock.data.types.v2_x.Schema.getSchemaResults()
    @ajax.whenQuerying('TypeDefinition').respondWith()
    initiative = @mom.getRecord('PortfolioItem/Initiative')
    @ajax.whenQuerying('PortfolioItem/Initiative').respondWith [initiative.data]
    @ajax.whenQuerying('artifact').respondWith()

  afterEach ->
    _.invoke Ext.ComponentQuery.query('treegridapp'), 'destroy'

  it 'should initialize', ->
    treeGridApp = Ext.create 'Rally.apps.treegrid.TreeGridApp', @getTreeGridAppConfig(false)
    expect(Ext.isDefined(treeGridApp)).toBeTruthy()
    treeGridApp.destroy()

  it 'should use the row expansion plugin', ->
    treeGridApp = @createTreeGridApp()
    plugins = treeGridApp.down('#gridBoard').gridConfig.plugins
    expect(_.find(plugins, ptype: 'rallytreegridexpandedrowpersistence')).toBeTruthy()
    treeGridApp.destroy()

  it 'should accept model strings', ->
    treeGridApp = @createTreeGridApp
      defaultSettings:
        modelNames: 'hierarchicalrequirement,defect'

    parentTypes = treeGridApp.down('#gridBoard').gridConfig.store.parentTypes
    expect(parentTypes.length).toBe 2
    expect(parentTypes).toContainAll ['hierarchicalrequirement','defect']
    treeGridApp.destroy()

#  this test is too implementation-specific but the staterestore is well-baked into the grid which isn't able to render in the test.
#  The true problem is the grid not rendering in the test, but hoping to come back to this when we need more grid-specific tests.
  it 'should wait to load grid\'s store until after grid\'s state is restored', ->
    treeGridApp = @createTreeGridApp()
    gridConfig = treeGridApp.down('#gridBoard').gridConfig
    gridStore = gridConfig.store
    stateRestoreListener = gridConfig.listeners.staterestore.fn
    loadSpy = @spy(gridStore, 'load')
    stateRestoreListener.call(treeGridApp,
      getStore: -> gridStore
    )
    @waitForCallback(loadSpy)

  it 'should load the grid\'s store if there is no state for the grid', ->
    @stub(Ext.state.Manager, 'get').returns null
    treeGridApp = @createTreeGridApp()
    gridConfig = treeGridApp.down('#gridBoard').gridConfig
    gridStore = gridConfig.store
    renderListener = gridConfig.listeners.render.fn
    loadSpy = @spy(gridStore, 'load')
    renderListener.call(
      treeGridApp,
      null,
      {
        store: gridStore
        stateId: 'someState'
      }
    )
    @waitForCallback(loadSpy)

  it 'should set the grid\'s plugins to an empty array', ->
    @stub(Ext.state.Manager, 'get').returns null
    treeGridApp = @createTreeGridApp()
    gridConfig = treeGridApp.down('#gridBoard')
    gridPlugins = gridConfig.plugins

    expect(gridPlugins).not.toBeNull
    expect(gridPlugins.length).toBeGreaterThan 0
    expect(_.find(gridPlugins, (plugin)->
      plugin.ptype == 'rallygridboardfieldpicker')).toBeTruthy()

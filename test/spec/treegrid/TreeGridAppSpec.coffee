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

  it 'should add the field picker plugin', ->
    @stub(Ext.state.Manager, 'get').returns null
    treeGridApp = @createTreeGridApp()
    gridBoard = treeGridApp.down('#gridBoard')
    gridPlugins = gridBoard.plugins

    expect(gridPlugins).not.toBeNull
    expect(gridPlugins.length).toBeGreaterThan 0
    expect(_.find(gridPlugins, (plugin)->
      plugin.ptype == 'rallygridboardfieldpicker')).toBeTruthy()

  it 'should not include the custom filter plugin by default', ->
    @stub(Ext.state.Manager, 'get').returns null
    treeGridApp = @createTreeGridApp()
    gridPlugins = treeGridApp.down('#gridBoard').plugins

    expect(_.find(gridPlugins, (plugin)->
      plugin.ptype == 'rallygridboardcustomfiltercontrol')).toBeFalsy()

  describe 'when including the custom filter plugin', ->
    beforeEach ->
      @stub(Ext.state.Manager, 'get').returns true
      @treeGridApp = @createTreeGridApp
        loadGridAfterStateRestore: false
        filterControlConfig:
          stateId: 'some-fake-test-state'

    it 'should be added to the array of plugins', ->
      gridPlugins = @treeGridApp.down('#gridBoard').plugins

      expect(_.find(gridPlugins, (plugin)->
        plugin.ptype == 'rallygridboardcustomfiltercontrol')).toBeTruthy()

    it 'should not load the grid on state restore', ->
      gridConfig = @treeGridApp.down('#gridBoard').gridConfig

      expect(gridConfig.listeners.staterestore).toBeUndefined()

    it 'should not reload the grid on render', ->
      gridConfig = @treeGridApp.down('#gridBoard').gridConfig

      expect(gridConfig.listeners.render).toBeUndefined()

  describe '#getModelNamesArray', ->
    it 'should parse modelNames as comma-delimited string (which is how modelNames are saved when a preference)', ->
      treeGridApp = @createTreeGridApp()
      modelNamesArray = treeGridApp.getModelNamesArray 'CindyCrawford,HeidiKlum,YoMama'
      expect(modelNamesArray).toEqual ['CindyCrawford','HeidiKlum','YoMama']

    it 'should accept modelNames as an array', ->
      treeGridApp = @createTreeGridApp()
      modelNamesArray = treeGridApp.getModelNamesArray ['CindyCrawford','HeidiKlum','YoMama']
      expect(modelNamesArray).toEqual ['CindyCrawford','HeidiKlum','YoMama']

    it 'should use the modelNames setting if no argument passed in', ->
      treeGridApp = @createTreeGridApp()
      @stub(treeGridApp, 'getSetting').returns 'YoMama'
      expect(treeGridApp.getModelNamesArray()).toEqual ['YoMama']

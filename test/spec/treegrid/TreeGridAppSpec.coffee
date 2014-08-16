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
    appCfg = _.extend @getTreeGridAppConfig(true)
    treeGridApp = Ext.create 'Rally.apps.treegrid.TreeGridApp', appCfg
    treeGridApp._loadApp()
    plugins = treeGridApp.down('#gridBoard').gridConfig.plugins
    expect(_.find(plugins, ptype: 'rallytreegridexpandedrowpersistence')).toBeTruthy()
    treeGridApp.destroy()

  it 'should accept model strings', ->
    appCfg = _.extend @getTreeGridAppConfig(true),
      defaultSettings:
        modelNames: 'hierarchicalrequirement,defect'

    treeGridApp = Ext.create 'Rally.apps.treegrid.TreeGridApp', appCfg
    treeGridApp._loadApp()
    parentTypes = treeGridApp.down('#gridBoard').gridConfig.store.parentTypes
    expect(parentTypes.length).toBe 2
    expect(parentTypes).toContainAll ['hierarchicalrequirement','defect']
    treeGridApp.destroy()

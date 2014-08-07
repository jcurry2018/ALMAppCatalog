Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.treegrid.TreeGridApp'
]

describe 'Rally.apps.treegrid.TreeGridApp', ->

  helpers
    getTreeGridAppConfig: (featureEnabled) ->
      modelNames: ['PortfolioItem/Project']
      getHeight: -> 250
      getContext: ->
        get: ->
        isFeatureEnabled: -> featureEnabled
        getScopedStateId: -> 'someStateId'

  beforeEach ->
    @ajax.whenQuerying('artifact').respondWith()

  afterEach ->
    _.invoke Ext.ComponentQuery.query('treegridapp'), 'destroy'

  it 'should initialize', ->
    treeGridApp = Ext.create 'Rally.apps.treegrid.TreeGridApp', @getTreeGridAppConfig(false)
    expect(Ext.isDefined(treeGridApp)).toBeTruthy()

  it 'should use the row expansion plugin', ->
    treeGridApp = Ext.create 'Rally.apps.treegrid.TreeGridApp', @getTreeGridAppConfig(true)
    expect(_.find(treeGridApp.down('#gridBoard').gridConfig.plugins, ptype: 'rallytreegridexpandedrowpersistence')).toBeTruthy()

  it 'should accept model strings', ->
    appCfg = _.extend @getTreeGridAppConfig(true),
      defaultSettings:
        modelNames: 'hierarchicalrequirement,defect'

    treeGridApp = Ext.create 'Rally.apps.treegrid.TreeGridApp', appCfg
    parentTypes = treeGridApp.down('#gridBoard').gridConfig.store.parentTypes
    expect(parentTypes.length).toBe 2
    expect(parentTypes).toContainAll ['hierarchicalrequirement','defect']

  it 'should show type picker in settings', ->
    treeGridApp = Ext.create 'Rally.apps.treegrid.TreeGridApp', @getTreeGridAppConfig(true)

    settings = treeGridApp.getSettingsFields()
    expect(settings[0].xtype).toBe 'rallypillpicker'
    expect(settings[0].comboBoxCfg.fieldLabel).toBe 'Objects'
    expect(settings[0].comboBoxCfg.modelType).toBe 'TypeDefinition'
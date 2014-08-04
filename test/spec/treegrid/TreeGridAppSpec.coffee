Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.treegrid.TreeGridApp'
]

describe 'Rally.apps.treegrid.TreeGridApp', ->

  helpers
    getTreeGridAppConfig: (featureEnabled) ->
      modelNames: ['PortfolioItem/Project']
      getContext: ->
        get: ->
        isFeatureEnabled: -> featureEnabled
        getScopedStateId: -> 'someStateId'

  beforeEach ->
    @piQueryStub = @ajax.whenQuerying('artifact').respondWith()

  afterEach ->
    if (@treeGridApp)
      @treeGridApp.destroy()

  it 'should initialize', ->
    @treeGridApp = Ext.create 'Rally.apps.treegrid.TreeGridApp', @getTreeGridAppConfig(false)
    expect(Ext.isDefined(@treeGridApp)).toBeTruthy()

  it 'should use the row expansion plugin', ->
    @treeGridApp = Ext.create 'Rally.apps.treegrid.TreeGridApp', @getTreeGridAppConfig(true)
    treeGrid = @treeGridApp.down 'rallytreegrid'

    expect(_.filter(treeGrid.plugins, ptype: 'rallytreegridexpandedrowpersistence').length).toBe 1

  it 'should fetch configured column attributes', ->
    @treeGridApp = Ext.create 'Rally.apps.treegrid.TreeGridApp', @getTreeGridAppConfig(true)
    @waitForCallback(@piQueryStub).then =>
      fetchedColumns = @piQueryStub.getCall(0).args[0].params.fetch.split(',')
      _.each(@treeGridApp.columnNames, (columnName) ->
        expect(fetchedColumns).toContain columnName
      )


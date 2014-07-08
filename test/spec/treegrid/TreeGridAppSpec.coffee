Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.treegrid.TreeGridApp'
]

describe 'Rally.apps.treegrid.TreeGridApp', ->

  beforeEach ->
    @ajax.whenQuerying('artifact').respondWith()

  afterEach ->
    if (@treeGridApp)
      @treeGridApp.destroy()

  it 'should initialize', ->
    @treeGridApp = Ext.create('Rally.apps.treegrid.TreeGridApp',
      getContext: ->
        get: ->
        isFeatureEnabled: -> false
        getScopedStateId: -> 'someStateId'
    )
    expect(Ext.isDefined(@treeGridApp)).toBeTruthy()

  it 'should persist row expansion if enabled', ->
    @treeGridApp = Ext.create('Rally.apps.treegrid.TreeGridApp',
      getContext: ->
        get: ->
        isFeatureEnabled: -> true
        getScopedStateId: -> 'someStateId'
    )
    treeGrid = @treeGridApp.down 'rallytreegrid'

    expect(_.filter(treeGrid.plugins, ptype: 'rallytreegridexpandedrowpersistence').length).toBe 1
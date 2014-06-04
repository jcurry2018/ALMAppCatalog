Ext = window.Ext4 || window.Ext

Ext.require []

describe 'Rally.apps.iterationtrackingboard.statsbanner.CollapseExpand', ->

  helpers
    createPane: (config = {}) ->
      @store = Ext.create 'Ext.data.Store',
        model: Rally.test.mock.data.WsapiModelFactory.getModel 'userstory'
      @pane = Ext.create 'Rally.apps.iterationtrackingboard.statsbanner.CollapseExpand', _.defaults config,
        renderTo: 'testDiv'
        store: @store

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'statsbannercollapseexpand'

  it 'should show collapse icon initially', ->
    @createPane()

    expect(@pane.expanded).toBeTruthy()
    expect(@pane.getEl().down('.icon-chevron-up').isVisible()).toBe true
    expect(@pane.getEl().down('.icon-chevron-down').isVisible()).toBe false

  it 'should show collapse icon when toggled while collapsed', ->
    @createPane expanded: false
    @pane.expand()

    expect(@pane.getEl().down('.icon-chevron-up').isVisible()).toBe true
    expect(@pane.getEl().down('.icon-chevron-down').isVisible()).toBe false

  it 'should show expand icon when toggled while expanded', ->
    @createPane expanded: true
    @pane.collapse()

    expect(@pane.getEl().down('.icon-chevron-up').isVisible()).toBe false
    expect(@pane.getEl().down('.icon-chevron-down').isVisible()).toBe true

  it 'should fire collapse event when collapse-expand is clicked and initially expanded', ->
    @createPane expanded: true
    @store.add @mom.getRecord 'userstory'
    collapseStub = @stub()
    @pane.on('collapse', collapseStub)
    @click(css: '.collapse-expand').then =>
      @waitForCallback collapseStub

  it 'should fire expand event when collapse-expand is clicked and initially collapsed', ->
    @createPane expanded: false
    @store.add @mom.getRecord 'userstory'
    expandStub = @stub()
    @pane.on('expand', expandStub)
    @click(css: '.collapse-expand').then =>
      @waitForCallback expandStub

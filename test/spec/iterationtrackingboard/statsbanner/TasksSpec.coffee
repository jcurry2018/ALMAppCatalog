Ext = window.Ext4 || window.Ext

Ext.require []

describe 'Rally.apps.iterationtrackingboard.statsbanner.Tasks', ->

  helpers
    createPane: (config={})->
      @store = Ext.create 'Ext.data.Store',
        model: Rally.test.mock.data.WsapiModelFactory.getModel 'userstory'
      @pane = Ext.create 'Rally.apps.iterationtrackingboard.statsbanner.Tasks', _.defaults config,
        renderTo: 'testDiv'
        store: @store

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'statsbannertasks'

  it 'should initialize the task count with 0', ->
    @createPane()

    expect(@pane.getEl().down('.stat-metric').dom.innerHTML).toContain '0'
    expect(@pane.getEl().down('.stat-secondary').dom.innerHTML).toContain 'Active'

  it 'should reset task count on datachange', ->
    @createPane count: 5

    @store.add @mom.getRecord 'userstory',
      values:
        Summary:
          Tasks:
            "state+blocked":
              "Defined+true": 1

    expect(@pane.getEl().down('.stat-metric').dom.innerHTML).toContain '1'

  it 'should update the task count on datachange', ->
    @createPane()

    @store.add @mom.getRecord 'userstory',
      values:
        Summary:
          Tasks:
            "state+blocked":
              "Completed+false": 1
              "Defined+true": 2

    expect(@pane.getEl().down('.stat-metric').dom.innerHTML).toContain '2'

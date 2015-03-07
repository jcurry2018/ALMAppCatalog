Ext = window.Ext4 || window.Ext

Ext.require []

describe 'Rally.apps.iterationtrackingboard.statsbanner.Defects', ->

  helpers
    createPane: (config = {}) ->
      @store = Ext.create 'Ext.data.Store',
        model: Rally.test.mock.data.WsapiModelFactory.getModel 'userstory'
      @pane = Ext.create 'Rally.apps.iterationtrackingboard.statsbanner.Defects', _.defaults config,
        renderTo: 'testDiv'
        store: @store

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'statsbannerdefects'

  it 'should initialize the defect count with 0', ->
    @createPane()

    expect(@pane.getEl().down('.stat-metric').dom.innerHTML).toContain '0'
    expect(@pane.getEl().down('.stat-secondary').dom.innerHTML).toContain 'Active'

  it 'should reset defect count on datachange', ->
    @createPane data: activeCount: 5

    @store.add @mom.getRecord 'defect',
      values:
        State: 'Open'

    expect(@pane.getEl().down('.stat-metric').dom.innerHTML).toContain '1'

  it 'should update the defect count on datachange with standalone defects', ->
    @createPane()
    @store.add @mom.getRecord 'defect',
      values:
        State: 'Open'

    expect(@pane.getEl().down('.stat-metric').dom.innerHTML).toContain '1'

  it 'should update the defect count on datachange with associated defects', ->
    @createPane()
    @store.add @mom.getRecord 'userstory',
      values:
        Summary:
          Defects:
            State:
              Closed: 1
              Open: 2

    expect(@pane.getEl().down('.stat-metric').dom.innerHTML).toContain '2'

  it 'should update the defect count on datachange with all defects', ->
    @createPane()
    @store.add [
      @mom.getRecord 'userstory',
        values:
          Summary:
            Defects:
              State:
                Closed: 1
                Open: 2
    , @mom.getRecord 'defect',
        values:
          State: 'Open'
    ]

    expect(@pane.getEl().down('.stat-metric').dom.innerHTML).toContain '3'
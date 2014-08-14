Ext = window.Ext4 || window.Ext;

Ext.require [
  'Rally.app.Context'
  'Rally.apps.iterationtrackingboard.Column'
]

describe 'Rally.apps.iterationtrackingboard.Column', ->

  beforeEach ->
    @cardboardHelper = Rally.test.helpers.CardBoard
    @stub(Rally.app.Context.prototype, 'getSubscription').returns StoryHierarchyEnabled: true

    @Model = Rally.test.mock.data.WsapiModelFactory.getUserStoryModel()

    @ajax.whenQuerying('userstory').respondWith()
    @ajax.whenQuerying('defect').respondWith()

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'iterationtrackingboardcolumn'

  it 'should only show stories with no children when querying user story', ->
    storeFilterSpy = @spy(Rally.apps.iterationtrackingboard.Column.prototype, 'getStoreFilter')
    @createColumn()

    expect(storeFilterSpy.returnValues[0][1].property).toBe 'DirectChildrenCount'
    expect(storeFilterSpy.returnValues[0][1].value).toBe 0

  it 'should not filter out parents when not querying user story', ->
    storeFilterSpy = @spy(Rally.apps.iterationtrackingboard.Column.prototype, 'getStoreFilter')
    @createColumn models: [Rally.test.mock.data.WsapiModelFactory.getDefectModel()]

    for returnValue in storeFilterSpy.returnValues
      for filter in returnValue
        expect(filter.property).not.toBe 'DirectChildrenCount'

  helpers
    createColumn: (config = {}) ->
      @cardboardHelper.createColumn(Ext.apply(
        columnClass: 'Rally.apps.iterationtrackingboard.Column'
        context: Rally.environment.getContext()
        value: 'Defined'
        attribute: 'ScheduleState'
        wipLimit: 0
        renderTo: 'testDiv'
        headerCell: Ext.get 'testDiv'
        contentCell: Ext.get 'testDiv'
        models: [@Model]
        , config)
      )

Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.BacklogBoardColumn'
  'Rally.apps.roadmapplanningboard.AppModelFactory'
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
]

describe 'Rally.apps.roadmapplanningboard.BacklogBoardColumn', ->

  helpers

    createColumn: (config = {}) ->
      config.store ?= Deft.Injector.resolve('featureStore')

      _.each config.store.data.getRange(), (record) ->
        record.set('ActualEndDate', null)

      @target = 'testDiv'
      columnReadyStub = @stub()

      @backlogColumn = @cardboardHelper.createColumn(Ext.merge
        columnClass: 'Rally.apps.roadmapplanningboard.BacklogBoardColumn'
        renderTo: @target
        contentCell: @target
        headerCell: @target
        lowestPIType: 'PortfolioItem/Feature'
        roadmap: Deft.Injector.resolve('roadmapStore').getById('roadmap-id-1')
        planStore: Deft.Injector.resolve('planStore')
        typeNames:
          child:
            name: 'Feature'
        listeners:
          ready: => columnReadyStub()
        , config
      )

      @once
        condition: => columnReadyStub.callCount > 0

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @cardboardHelper = Rally.test.helpers.CardBoard

  afterEach ->
    Deft.Injector.reset()
    @backlogColumn?.destroy()

  it 'has a backlog filter', ->
    @createColumn().then =>
      expect(@backlogColumn.getCards().length).toBe(5)

  it 'will filter by roadmap in addition to feature and plans', ->
    planStore = Ext.create 'Rally.data.Store',
      model: Rally.apps.roadmapplanningboard.AppModelFactory.getPlanModel()
      proxy:
        type: 'memory'
      data: []

    store = Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.getFeatureStoreFixture()

    @createColumn(
      store: store
      planStore: planStore
    ).then =>
      expect(@backlogColumn.getCards().length).toBe(10)

  it 'should have a null filter for actual end date', ->
    @createColumn().then =>
      filter = @backlogColumn.getStoreFilter()
      expect(filter.operator).toBe '='
      expect(filter.property).toBe 'ActualEndDate'
      expect(filter.value).toBe 'null'


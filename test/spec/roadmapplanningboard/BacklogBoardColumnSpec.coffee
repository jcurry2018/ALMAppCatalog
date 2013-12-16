Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.BacklogBoardColumn'
  'Rally.apps.roadmapplanningboard.AppModelFactory'
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
]

describe 'Rally.apps.roadmapplanningboard.BacklogBoardColumn', ->
  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()

    @target = 'testDiv'
    @backlogColumn = Ext.create 'Rally.apps.roadmapplanningboard.BacklogBoardColumn',
      renderTo: @target
      contentCell: @target
      headerCell: @target
      store: Deft.Injector.resolve('featureStore')
      planStore: Deft.Injector.resolve('planStore')
      lowestPIType: 'PortfolioItem/Feature'
      roadmap: Deft.Injector.resolve('roadmapStore').getById('413617ecef8623df1391fabc')

    return @backlogColumn

  afterEach ->
    Deft.Injector.reset()
    @backlogColumn?.destroy()

  it 'has a backlog filter', ->
    expect(@backlogColumn.getCards().length).toBe(5)

  it 'will filter by roadmap in addition to feature and plans', ->
    planStore = Ext.create 'Rally.data.Store',
      model: Rally.apps.roadmapplanningboard.AppModelFactory.getPlanModel()
      proxy:
        type: 'memory'
      data: []

    column = Ext.create 'Rally.apps.roadmapplanningboard.BacklogBoardColumn',
      renderTo: 'testDiv'
      contentCell: 'testDiv'
      headerCell: 'testDiv'
      store: Deft.Injector.resolve('featureStore')
      planStore: planStore
      lowestPIType: 'feature'

    expect(column.getCards().length).toBe(10)

    column.destroy()

  it 'should have a null filter for actual end date', ->
    filter = @backlogColumn.getStoreFilter()
    expect(filter.operator).toBe '='
    expect(filter.property).toBe 'ActualEndDate'
    expect(filter.value).toBe 'null'


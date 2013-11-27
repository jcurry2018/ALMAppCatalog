Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.BacklogBoardColumn'
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
      lowestPIType: 'PortfolioItem/Feature'
      roadmap: Deft.Injector.resolve('roadmapStore').getById('413617ecef8623df1391fabc')

    return @backlogColumn

  afterEach ->
    Deft.Injector.reset()
    @backlogColumn?.destroy()

  it 'is using injected stores', ->
    expect(@backlogColumn.planStore).toBeTruthy()

  it 'has a backlog filter', ->
    expect(@backlogColumn.getCards().length).toBe(5)

  it 'will filter by roadmap in addition to feature and plans', ->
    roadmapModel = Ext.create 'Rally.apps.roadmapplanningboard.RoadmapModel',
      id: 'Foo',
      name: "bar",
      plans: []

    column = Ext.create 'Rally.apps.roadmapplanningboard.BacklogBoardColumn',
      renderTo: 'testDiv'
      contentCell: 'testDiv'
      headerCell: 'testDiv'
      roadmap: roadmapModel
      store: Deft.Injector.resolve('featureStore')
      lowestPIType: 'feature'

    expect(column.getCards().length).toBe(10)

    column.destroy()

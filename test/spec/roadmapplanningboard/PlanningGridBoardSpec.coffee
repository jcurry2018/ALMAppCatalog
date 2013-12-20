Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.PlanningGridBoard'
]

describe 'Rally.apps.roadmapplanningboard.PlanningGridBoard', ->
  helpers
    createPermissionsStub: (config) ->
      @stub Rally.environment.getContext(), 'getPermissions', ->
        isSubscriptionAdmin: ->
          !!config.subAdmin
        isWorkspaceAdmin: ->
          !!config.workspaceAdmin
        isProjectEditor: ->
          !!config.projectEditor

    createGridboard: (expectError = false, context = Rally.environment.getContext()) ->
      @gridboard = Ext.create 'Rally.apps.roadmapplanningboard.PlanningGridBoard',
        roadmap: @roadmapStore.first()
        timeline: @timelineStore.first()
        context: context
        typeName: 'Feature'
        modelNames: ['PortfolioItem/Feature']
        renderTo: 'testDiv'

      @waitForComponentReady(@gridboard)

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @timelineStore = Deft.Injector.resolve('timelineStore')
    @roadmapStore = Deft.Injector.resolve('roadmapStore')
    @ajax.whenQuerying('TypeDefinition').respondWith Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemFeature')
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith []

  afterEach ->
    @gridboard.destroy()
    Deft.Injector.reset()

  it 'should wrap a roadmap planning board', ->
    @createGridboard().then =>
      expect(@gridboard.getGridOrBoard()).toBeTruthy()
      expect(@gridboard.getGridOrBoard().$className).toEqual('Rally.apps.roadmapplanningboard.PlanningBoard')

  it 'should render feedback', ->
    @createGridboard().then =>
      expect(!!@gridboard.down('#feedback')).toBe true

  it 'should have a add new button', ->
    @createGridboard().then =>
      expect(!!@gridboard.down('#new')).toBe true

  it 'should set isAdmin on gridboard to true if user is a Sub Admin', ->
    @createPermissionsStub(subAdmin: true)
    @createGridboard().then =>
      expect(@gridboard.getGridOrBoard().isAdmin).toBe true

  it 'should set isAdmin on gridboard to true if user is a WS Admin', ->
    @createPermissionsStub(workspaceAdmin: true)
    @createGridboard().then =>
      expect(@gridboard.getGridOrBoard().isAdmin).toBe true

  it 'should set isAdmin on gridboard to false if user is not a Sub or WS Admin', ->
    @createPermissionsStub(subAdmin: false, workspaceAdmin: false)
    @createGridboard().then =>
      expect(@gridboard.getGridOrBoard().isAdmin).toBe false

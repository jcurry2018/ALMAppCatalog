Ext = window.Ext4 || window.Ext

Ext.define 'Rally.apps.roadmapplanningboard.DeftInjector', { singleton: true, init: Ext.emptyFn }

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp'
  'Rally.test.mock.ModelObjectMother'
]

describe 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', ->

  helpers
    createApp: ->
      context = Ext.create 'Rally.app.Context',
        initialValues:
          project: Rally.environment.getContext().getProject()
          workspace: Rally.environment.getContext().getWorkspace()
          user: Rally.environment.getContext().getUser()
          subscription: Rally.environment.getContext().getSubscription()

      @app = Ext.create 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp',
        context: context
        renderTo: 'testDiv'

      @waitForComponentReady(@app).then =>
        @planningBoard = @app.down 'roadmapplanningboard'

     createPermissionsStub: (config) ->
       @stub Rally.environment.getContext(), 'getPermissions', ->
         isSubscriptionAdmin: -> !!config.subAdmin
         isWorkspaceAdmin: -> !!config.workspaceAdmin

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @ajax.whenQuerying('TypeDefinition').respondWith Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemFeature')
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith []

  afterEach ->
    @app?.destroy()
    Deft.Injector.reset()

  it 'should render a planning board', ->
    @createApp().then =>
      roadmapId = Deft.Injector.resolve('roadmapStore').first().getId()
      expect(@planningBoard.roadmapId).toBe roadmapId

  it 'should set isAdmin on planning board to true if user is a Sub Admin', ->
    @createPermissionsStub(subAdmin: true)
    @createApp().then =>
      expect(@planningBoard.isAdmin).toBe true

  it 'should set isAdmin on planning board to true if user is a WS Admin', ->
    @createPermissionsStub(workspaceAdmin: true)
    @createApp().then =>
      expect(@planningBoard.isAdmin).toBe true

  it 'should set isAdmin on planning board to false if user is not a Sub or WS Admin', ->
    @createPermissionsStub(subAdmin: false, workspaceAdmin: false)
    @createApp().then =>
      expect(@planningBoard.isAdmin).toBe false

  describe 'Service error handling', ->

    it 'should display a friendly notification if any service (planning, timeline, WSAPI) is unavailable', ->
      @createApp().then =>
        Ext.Ajax.fireEvent('requestexception', null, null, { operation: requester: @app })

        expect(@app.getEl().getHTML()).toContain 'temporarily unavailable'
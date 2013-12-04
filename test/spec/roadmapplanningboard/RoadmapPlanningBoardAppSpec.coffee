Ext = window.Ext4 || window.Ext

Ext.define 'Rally.apps.roadmapplanningboard.DeftInjector', { singleton: true, init: Ext.emptyFn }

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp'
  'Rally.test.mock.ModelObjectMother'
]

describe 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', ->
  helpers
    createApp: (expectError = false) ->
      context = Ext.create 'Rally.app.Context',
        initialValues:
          project: Rally.environment.getContext().getProject()
          workspace: Rally.environment.getContext().getWorkspace()
          user: Rally.environment.getContext().getUser()
          subscription: Rally.environment.getContext().getSubscription()

      @app = Ext.create 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp',
        context: context
        renderTo: 'testDiv'

      if expectError
        @once
          condition: => @errorNotifyStub.calledOnce
      else
        @waitForComponentReady(@app).then =>
          @planningBoard = @app.down 'roadmapplanningboard'

    createPermissionsStub: (config) ->
      @stub Rally.environment.getContext(), 'getPermissions', ->
        isSubscriptionAdmin: ->
          !!config.subAdmin
        isWorkspaceAdmin: ->
          !!config.workspaceAdmin

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @timelineStore = Deft.Injector.resolve('timelineStore')
    @roadmapStore = Deft.Injector.resolve('roadmapStore')
    @errorNotifyStub = @stub Rally.ui.notify.Notifier, 'showError'
    @ajax.whenQuerying('TypeDefinition').respondWith Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemFeature')
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith []

  afterEach ->
    @app?.destroy()
    Deft.Injector.reset()

  it 'should render a planning board with a timeline', ->
    @createApp().then =>
      expect(@planningBoard.timeline.getId()).toBe @timelineStore.first().getId()

  it 'should render a planning board with a roadmap', ->
    @createApp().then =>
      expect(@planningBoard.roadmap.getId()).toBe @roadmapStore.first().getId()

  it 'should notify of error if the timeline store fails to load', ->
    @stub @timelineStore, 'load', ->
      deferred = new Deft.promise.Deferred()
      deferred.reject({storeServiceName: 'Timeline'});
      deferred.promise

    @createApp(true).then =>
      expect(@errorNotifyStub.lastCall.args[0]).toEqual
        message: 'Failed to load app: Timeline service data load issue'

  it 'should notify of error if the roadmap store fails to load', ->
    @stub @roadmapStore, 'load', ->
      deferred = new Deft.promise.Deferred()
      deferred.reject({storeServiceName: 'Planning'});
      deferred.promise

    @createApp(true).then =>
      expect(@errorNotifyStub.lastCall.args[0]).toEqual
        message: 'Failed to load app: Planning service data load issue'

  it 'should notify of error if there is no roadmap available', ->
    @stub @roadmapStore, 'load', ->
      deferred = new Deft.promise.Deferred()
      deferred.resolve { records: {} }
      deferred.promise

    @createApp(true).then =>
      expect(@errorNotifyStub.lastCall.args[0]).toEqual
        message: 'No roadmap available'

  it 'should notify of error if there is no timeline available', ->
    @stub @timelineStore, 'load', ->
      deferred = new Deft.promise.Deferred()
      deferred.resolve { records: {} }
      deferred.promise

    @createApp(true).then =>
      expect(@errorNotifyStub.lastCall.args[0]).toEqual
        message: 'No timeline available'

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
        Ext.Ajax.fireEvent('requestexception', null, null, { operation:
          requester: @app.controller })

        expect(@app.getEl().getHTML()).toContain 'temporarily unavailable'
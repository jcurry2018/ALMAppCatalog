Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardContainer'
  'Rally.test.mock.ModelObjectMother'
]

describe 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardContainer', ->
  helpers
    createContainer: (expectError = false, context = Rally.environment.getContext()) ->
      @container = Ext.create 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardContainer',
        renderTo: 'testDiv'
        context: context

      if expectError
        @once
          condition: => @errorNotifyStub.calledOnce
      else
        @waitForComponentReady(@container).then =>
          @planningBoard = @container.down 'roadmapplanningboard'

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
    @container?.destroy()
    Deft.Injector.reset()

  it 'should use the global context if none provided', ->
    @createContainer().then =>
      expect(@container.getContext()).toBe Rally.environment.getContext()

  it 'should use the provided context', ->
    context = Ext.create 'Rally.app.Context',
      initialValues:
        project: Rally.environment.getContext().getProject()
        workspace: Rally.environment.getContext().getWorkspace()
        user: Rally.environment.getContext().getUser()
        subscription: Rally.environment.getContext().getSubscription()

    @createContainer(false, context).then =>
      expect(@container.getContext()).toNotBe Rally.environment.getContext()
      expect(@container.getContext()).toBe context

  it 'should render feedback', ->
    @createContainer().then =>
      expect(!!@container.feedback).toBe true
      expect(!!@container.getEl().down('.feedbackcontainer')).toBe true

  it 'should render a planning board with a timeline', ->
    @createContainer().then =>
      expect(@planningBoard.timeline.getId()).toBe @timelineStore.first().getId()

  it 'should render a planning board with a roadmap', ->
    @createContainer().then =>
      expect(@planningBoard.roadmap.getId()).toBe @roadmapStore.first().getId()

  it 'should notify of error if the timeline store fails to load', ->
    @stub @timelineStore, 'load', ->
      deferred = new Deft.promise.Deferred()
      deferred.reject({storeServiceName: 'Timeline'});
      deferred.promise

    @createContainer(true).then =>
      expect(@errorNotifyStub.lastCall.args[0]).toEqual
        message: 'Failed to load app: Timeline service data load issue'

  it 'should notify of error if the roadmap store fails to load', ->
    @stub @roadmapStore, 'load', ->
      deferred = new Deft.promise.Deferred()
      deferred.reject({storeServiceName: 'Planning'});
      deferred.promise

    @createContainer(true).then =>
      expect(@errorNotifyStub.lastCall.args[0]).toEqual
        message: 'Failed to load app: Planning service data load issue'

  it 'should notify of error if there is no roadmap available', ->
    @stub @roadmapStore, 'load', ->
      deferred = new Deft.promise.Deferred()
      deferred.resolve { records: {} }
      deferred.promise

    @createContainer(true).then =>
      expect(@errorNotifyStub.lastCall.args[0]).toEqual
        message: 'No roadmap available'

  it 'should notify of error if there is no timeline available', ->
    @stub @timelineStore, 'load', ->
      deferred = new Deft.promise.Deferred()
      deferred.resolve { records: {} }
      deferred.promise

    @createContainer(true).then =>
      expect(@errorNotifyStub.lastCall.args[0]).toEqual
        message: 'No timeline available'

  it 'should set isAdmin on planning board to true if user is a Sub Admin', ->
    @createPermissionsStub(subAdmin: true)
    @createContainer().then =>
      expect(@planningBoard.isAdmin).toBe true

  it 'should set isAdmin on planning board to true if user is a WS Admin', ->
    @createPermissionsStub(workspaceAdmin: true)
    @createContainer().then =>
      expect(@planningBoard.isAdmin).toBe true

  it 'should set isAdmin on planning board to false if user is not a Sub or WS Admin', ->
    @createPermissionsStub(subAdmin: false, workspaceAdmin: false)
    @createContainer().then =>
      expect(@planningBoard.isAdmin).toBe false

  describe 'Service error handling', ->
    it 'should display a friendly notification if any service (planning, timeline, WSAPI) is unavailable', ->
      @createContainer().then =>
        Ext.Ajax.fireEvent('requestexception', null, null, { operation:
          requester: @container })

        expect(@container.getEl().getHTML()).toContain 'temporarily unavailable'
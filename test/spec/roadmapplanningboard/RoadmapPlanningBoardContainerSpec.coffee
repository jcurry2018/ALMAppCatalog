Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardContainer'
  'Rally.test.mock.ModelObjectMother'
]

describe 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardContainer', ->
  helpers
    createContainer: (expectError = false, config = {}, context = Rally.environment.getContext()) ->
      @container = Ext.create 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardContainer',
        Ext.merge config,
          renderTo: 'testDiv'
          context: context

      if expectError
        @once
          condition: => @errorNotifyStub.calledOnce
      else
        @waitForComponentReady(@container).then =>
          @waitForComponentReady(@container.gridboard).then =>
            @planningBoard = @container.down 'roadmapplanningboard'

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

    @createContainer(false, {}, context).then =>
      expect(@container.getContext()).toNotBe Rally.environment.getContext()
      expect(@container.getContext()).toBe context

  it 'should render a gridboard board with a timeline', ->
    @createContainer().then =>
      expect(@container.gridboard.timeline.getId()).toBe @timelineStore.first().getId()

  it 'should render a gridboard board with a roadmap', ->
    @createContainer().then =>
      expect(@container.gridboard.timeline.getId()).toBe @timelineStore.first().getId()

  it 'should define height for gridboard based on content window', ->
    Ext.DomHelper.append Ext.getBody(), '<div id="content" style="height: 100px;"><div class="page" style="height: 20px;"></div></div>'
    @createContainer().then =>
      expect(@container.gridboard.getHeight()).toBe 80

  it 'should define height for gridboard based on container height', ->
    @createContainer(false, {height: 200}).then =>
      expect(@container.gridboard.getHeight()).toBe 200

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

  describe 'Service error handling', ->
    it 'should display a friendly notification if any service (planning, timeline, WSAPI) is unavailable', ->
      @createContainer().then =>
        Ext.Ajax.fireEvent('requestexception', null, null, { operation:
          requester: @container })

        expect(@container.getEl().getHTML()).toContain 'temporarily unavailable'
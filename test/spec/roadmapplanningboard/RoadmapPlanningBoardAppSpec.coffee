Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp',
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper',
  'Rally.test.mock.ModelObjectMother'
]

describe 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', ->
  helpers
    createApp: (expectError = false, config = {}) ->
      config = _.extend
        context: Ext.create 'Rally.app.Context',
          initialValues:
            Ext.merge
              project:
                ObjectID: 123456
                _ref: 'project/ref'
                Name: 'TestProject'
              workspace:
                WorkspaceConfiguration:
                  DragDropRankingEnabled: true
            , {}

        settings: {}
        renderTo: 'testDiv'
      ,config

      @app = Ext.create 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', config

      if expectError
        @once
          condition: => @errorNotifyStub.calledOnce
      else
        @waitForComponentReady(@app).then =>
          @planningBoard = @app.down 'roadmapplanningboard'

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

  it 'should use the provided context', ->
    @createApp().then =>
      expect(@app.getContext().getProject().ObjectID).toBe 123456

  it 'should render a planning board with a timeline', ->
    @createApp().then =>
      expect(@planningBoard.timeline.getId()).toBe @timelineStore.first().getId()

  it 'should render a planning board with a roadmap', ->
    @createApp().then =>
      expect(@planningBoard.timeline.getId()).toBe @timelineStore.first().getId()

  it 'should define height based on content window', ->
    Ext.DomHelper.append Ext.getBody(), '<div id="content" style="height: 600px;"><div class="page" style="height: 20px;"></div></div>'
    @createApp().then =>
      #test range as jasmine does not like to render html the same with local and test server
      appHeight = @app._computePanelContentAreaHeight()
      expect(appHeight).toBe >= 570
      expect(appHeight).toBe <= 600

  it 'should define height for app', ->
    @createApp(false, {height: 1000}).then =>
      expect(@app._computePanelContentAreaHeight()).toBe = 1000

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

  describe 'Service error handling', ->
    it 'should display a friendly notification if any service (planning, timeline, WSAPI) is unavailable', ->
      @createApp().then =>
        Ext.Ajax.fireEvent('requestexception', null, null, { operation:
          requester: @app })

        expect(@app.getEl().getHTML()).toContain 'temporarily unavailable'
Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp'
  'Rally.apps.roadmapplanningboard.SplashContainer'
  'Rally.test.mock.ModelObjectMother'
]

describe 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', ->
  helpers
    createApp: (expectError = false, config = {}) ->
      config = _.extend
        alreadyGotIt: true
        expectSplash: false
        isAdmin: true
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
      , config

      @stub Rally.apps.roadmapplanningboard.SplashContainer, 'loadPreference', =>
        pref = {}
        pref[Rally.apps.roadmapplanningboard.SplashContainer.PREFERENCE_NAME] = config.alreadyGotIt
        deferred = new Deft.Deferred()
        deferred.resolve pref
        deferred.promise

      @app = Ext.create 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', config

      if expectError
        @once
          condition: => @errorNotifyStub.calledOnce
      else
        @waitForComponentReady(@app).then =>
          if !config.expectSplash
            @waitForComponentReady('#gridboard').then =>
              @planningBoard = @app.down 'roadmapplanningboard'
          else
            deferred = Ext.create 'Deft.Deferred'
            Ext.defer -> deferred.resolve()
            deferred.promise

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
      appHeight = @app._computeFullPagePanelContentAreaHeight()
      expect(appHeight >= 570).toBe true
      expect(appHeight <= 600).toBe true

  it 'should define board height based on app height', ->
    @createApp(false, {height: 1000}).then =>
      #test range as jasmine does not like to render html the same with local and test server
      boardHeight = @planningBoard.getHeight()
      expect(boardHeight >= 970).toBe true
      expect(boardHeight <= 1000).toBe true

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

  it 'should show the splash container if there is no roadmap', ->
    @roadmapStore.data.clear()
    @stub @roadmapStore, 'load', ->
      Deft.Promise.when { records: {} }

    @createApp(false, {expectSplash: true}).then =>
      expect(@app).not.toContainComponent '#got-it'
      expect(@app).toContainComponent '#roadmap-splash-container'

  it 'should show the splash container if there is no timeline', ->
    @timelineStore.data.clear()
    @stub @timelineStore, 'load', ->
      Deft.Promise.when { records: {} }

    @createApp(false, {expectSplash: true}).then =>
      expect(@app).not.toContainComponent '#got-it'
      expect(@app).toContainComponent '#roadmap-splash-container'

  it 'should show the splash container if the preference is not set', ->
    @createApp(false, {expectSplash: true, alreadyGotIt: false}).then =>
      expect(@app).toContainComponent '#got-it'
      expect(@app).toContainComponent '#roadmap-splash-container'

  it 'should show the gridboard after clicking the got it button', ->
    @createApp(false, {expectSplash: true, alreadyGotIt: false}).then =>
      @click(css: '.primary').then =>
        @waitForComponentReady(@app.down('#gridboard')).then =>
          expect(@app).toContainComponent '#gridboard'

  describe 'Service error handling', ->
    it 'should display a friendly notification if any service (planning, timeline, WSAPI) is unavailable', ->
      @createApp().then =>
        Ext.Ajax.fireEvent('requestexception', null, null, { operation:
          requester: @app })

        expect(@app.getEl().getHTML()).toContain 'temporarily unavailable'
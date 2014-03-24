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
    @isBrowserSupportedStub = @stub Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp::, '_isSupportedBrowser', =>
      true
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
      expect(boardHeight >= 950).toBe true
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

  describe '_isSupportedBrowser', ->
    beforeEach ->
      @isBrowserSupportedStub.restore()

    userAgentStrings =
      "Chrome 29": ["Mozilla/5.0 (X11; CrOS i686 4319.74.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.57 Safari/537.36", false]
      "Chrome 33": ["Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36", true]
      "Chrome No Version": ["Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome Safari/537.36", false]
      "IE 10": ["Mozilla/5.0 (compatible; MSIE 10.6; Windows NT 6.1; Trident/5.0; InfoPath.2; SLCC1; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET CLR 2.0.50727) 3gpp-gba UNTRUSTED/1.0", true]
      "IE 8": ["Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)", false]
      "Opera": ["Mozilla/5.0 (Windows NT 6.0; rv:2.0) Gecko/20100101 Firefox/4.0 Opera 12.14", false]
      "Mac_Safari 6": ["Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5355d Safari/8536.25", true]
      "Mac_Safari 5": ["Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.13+ (KHTML, like Gecko) Version/5.1.7 Safari/534.57.2", false]
      "Firefox 28": ["Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:25.0) Gecko/20100101 Firefox/28.0", true]
      "Firefox 25": ["Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:25.0) Gecko/20100101 Firefox/25.0", false]
      "Firefox No Version": ["Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:25.0) Gecko/20100101 Firefox/", false]
      "Empty String": ["", false]
      "Random Gibberish": ["fiwuehfwieufhweiufhweiuf", false]
      "Midori": ["Mozilla/5.0 (X11; U; Linux i686; fr-fr) AppleWebKit/525.1+ (KHTML, like Gecko, Safari/525.1+) midori/1.19", false]

    _.each userAgentStrings, ([userAgent, isSupported], displayName) ->
      #supportedText = if isSupported then  'supported' else 'unsupported'
      it "should state that #{displayName} is #{if isSupported then  'supported' else 'unsupported'}", ->

        window.navigator.__defineGetter__ 'userAgent', () -> userAgent

        browserInfo = Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp::_getBrowserInfo()
        expect(Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp::_isSupportedBrowser browserInfo).toBe isSupported

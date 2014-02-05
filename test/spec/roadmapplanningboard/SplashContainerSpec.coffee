Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.SplashContainer'
]

describe 'Rally.apps.roadmapplanningboard.SplashContainer', ->

  helpers
    createSplashContainer: (config) ->
      @container = Ext.create 'Rally.apps.roadmapplanningboard.SplashContainer', _.extend
        showGetStarted: true
        showGotIt: true
        renderTo: 'testDiv'
      , config

    clickButton: (selector) ->
      @click(id: @container.down(selector).id)

  beforeEach ->
    @ajax.whenQuerying('Preference').respondWith {}
    @expectedPreferenceSaveArgs =
      filterByUser: true
      filterByName: 'RoadmapSplashPreference'
      settings:
        RoadmapSplashPreference: true
    @preferenceSaveStub = @stub Rally.data.PreferenceManager, 'update', ->
      deferred = new Deft.Deferred()
      deferred.resolve {}
      deferred.promise

  it 'should render the carousel', ->
    @createSplashContainer()
    expect(@container).toContainComponent '#carousel'

  describe '"Get Started" button', ->

    it 'should be visible if showGetStarted config is true', ->
      @createSplashContainer(showGetStarted: true)
      expect(@container).toContainComponent '#get-started'

    it 'should not be visible if showGetStarted config is false', ->
      @createSplashContainer(showGetStarted: false)
      expect(@container).not.toContainComponent '#get-started'

    it 'should fire getstarted event when clicked', ->
      @createSplashContainer()
      eventStub = @stub()
      @container.on 'getstarted', eventStub
      @clickButton('#get-started').then =>
        expect(eventStub).toHaveBeenCalledOnce()

    it 'should save preferences when get clicked', ->
      @createSplashContainer()
      @clickButton('#get-started').then =>
        expect(@preferenceSaveStub).toHaveBeenCalledWith @expectedPreferenceSaveArgs


  describe '"Got It" button', ->

    it 'should be visible if the showGotIt config is true', ->
      @createSplashContainer(showGotIt: true)
      expect(@container).toContainComponent '#got-it'

    it 'should not be visible if the showGotIt config is false', ->
      @createSplashContainer(showGotIt: false)
      expect(@container).not.toContainComponent '#got-it'

    it 'should fire gotit event when clicked', ->
      @createSplashContainer()
      eventStub = @stub()
      @container.on 'gotit', eventStub
      @clickButton('#got-it').then =>
        expect(eventStub).toHaveBeenCalledOnce()

    it 'should save preferences when clicked', ->
      @createSplashContainer()
      @clickButton('#got-it').then =>
        expect(@preferenceSaveStub).toHaveBeenCalledWith @expectedPreferenceSaveArgs



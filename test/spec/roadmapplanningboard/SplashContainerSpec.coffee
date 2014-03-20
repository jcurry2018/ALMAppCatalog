Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.SplashContainer'
]

describe 'Rally.apps.roadmapplanningboard.SplashContainer', ->

  helpers
    createSplashContainer: (config) ->
      @container = Ext.create 'Rally.apps.roadmapplanningboard.SplashContainer', _.extend
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

    describe 'when showGetStarted is true', ->

      beforeEach ->
        @createSplashContainer(showGetStarted: true)

      it 'should be visible', ->
        expect(@container).toContainComponent '#get-started'

      it 'should fire getstarted event when clicked', ->
        eventStub = @stub()
        @container.on 'getstarted', eventStub
        @clickButton('#get-started').then =>
          expect(eventStub).toHaveBeenCalledOnce()

      it 'should save preferences when get clicked', ->
        @clickButton('#get-started').then =>
          expect(@preferenceSaveStub).toHaveBeenCalledWith @expectedPreferenceSaveArgs

  describe 'when showGetStarted is false', ->

    beforeEach ->
      @createSplashContainer(showGetStarted: false)

    it 'should not be visible if showGetStarted config is false', ->
      expect(@container).not.toContainComponent '#get-started'

  describe '"Got It" button', ->

    describe 'when showGotIt is true', ->

      beforeEach ->
        @createSplashContainer(showGotIt: true)

      it 'should be visible if the showGotIt config is true', ->
        expect(@container).toContainComponent '#got-it'

      it 'should fire gotit event when clicked', ->
        eventStub = @stub()
        @container.on 'gotit', eventStub
        @clickButton('#got-it').then =>
          expect(eventStub).toHaveBeenCalledOnce()

      it 'should save preferences when clicked', ->
        @clickButton('#got-it').then =>
          expect(@preferenceSaveStub).toHaveBeenCalledWith @expectedPreferenceSaveArgs

    describe 'when showGotIt is false', ->

      beforeEach ->
        @createSplashContainer(showGotIt: false)

      it 'should not be visible if the showGotIt config is false', ->
        expect(@container).not.toContainComponent '#got-it'

Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.SplashContainer'
]

describe 'Rally.apps.roadmapplanningboard.SplashContainer', ->

  helpers
    createSplashContainer: (config) ->
      @container = Ext.create 'Rally.apps.roadmapplanningboard.SplashContainer', _.extend
        isAdmin: true
        showGotIt: true
        renderTo: 'testDiv'
      , config

    clickButton: (selector) ->
      @click(id: @container.down(selector).id)

  beforeEach ->
    @ajax.whenQuerying('Preference').respondWith {}

  it 'should show the get started button if user is an admin', ->
    @createSplashContainer(isAdmin: true)
    expect(@container).toContainComponent '#get-started'

  it 'should not show get started button if user is not an admin', ->
    @createSplashContainer(isAdmin: false)
    expect(@container).not.toContainComponent '#get-started'

  it 'should show got it button if gotIt config is true', ->
    @createSplashContainer(showGotIt: true)
    expect(@container).toContainComponent '#got-it'

  it 'should not show got it button if the gotIt config is false', ->
    @createSplashContainer(showGotIt: false)
    expect(@container).not.toContainComponent '#got-it'

  it 'should render the carousel', ->
    @createSplashContainer()
    expect(@container).toContainComponent '#carousel'

  it 'should fire gotit event when got it button is clicked', ->
    @createSplashContainer()
    eventStub = @stub()
    @container.on 'gotit', eventStub
    @clickButton('#got-it').then =>
      expect(eventStub).toHaveBeenCalledOnce()

  it 'should fire getstarted event when get started button is clicked', ->
    @createSplashContainer()
    eventStub = @stub()
    @container.on 'getstarted', eventStub
    @clickButton('#get-started').then =>
      expect(eventStub).toHaveBeenCalledOnce()
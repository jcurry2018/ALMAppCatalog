Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.plugin.RoadmapCollapsableFixedHeader'
  'Rally.apps.roadmapplanningboard.PlanningBoard'
  'Rally.apps.roadmapplanningboard.AppModelFactory'
  'Rally.data.PreferenceManager'
]

describe 'Rally.apps.roadmapplanningboard.plugin.RoadmapCollapsableFixedHeader', ->

  helpers
    stubExpandStatePreference: (state) ->
      @loadStub = @stub Rally.data.PreferenceManager, 'load', ->
        deferred = new Deft.promise.Deferred()
        result = {}
        result[Rally.apps.roadmapplanningboard.PlanningBoard.PREFERENCE_NAME] = state
        deferred.resolve result
        deferred.promise

    createCardboard: (expandedState = 'true') ->
      @stubExpandStatePreference(expandedState)

      roadmapStore = Deft.Injector.resolve('roadmapStore')
      timelineStore = Deft.Injector.resolve('timelineStore')
      config =
        roadmap: roadmapStore.first()
        timeline: timelineStore.first()
        renderTo: 'testDiv'
        isAdmin: true
        types: ['PortfolioItem/Feature']
        context: Rally.environment.getContext()
        plugins: [{ptype: 'rallyroadmapcollapsableheader'}]
        typeNames:
            child:
              name: 'Feature'
        height: 500

      @cardboard = Ext.create 'Rally.apps.roadmapplanningboard.PlanningBoard', config

      @waitForComponentReady(@cardboard)

    toggleExpansion: ->
      collapseStub = @stub()
      @cardboard.on 'headersizechanged', collapseStub
      @click(css: '.header-toggle-button').then =>
        @once
          condition: ->
            collapseStub.called

    getCollapsableHeaderElements: ->
      _.map(@cardboard.getEl().query('.roadmap-header-collapsable'), Ext.get)

    clickAddNewButton: ->
      @click(css: '.scroll-button.rly-right')

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()

  afterEach ->
    Deft.Injector.reset()

  describe 'collapsed header preference', ->
    it 'should be loaded when cardboad is created', ->
      @createCardboard('false').then =>
        expect(@loadStub).toHaveBeenCalled()

    it 'should be saved when toggle button is clicked', ->
      updateSpy = @spy Rally.data.PreferenceManager, 'update'
      @createCardboard().then =>
        @toggleExpansion().then =>
          expect(updateSpy).toHaveBeenCalled()

  describe 'cardboard creation', ->
    it 'should show expanded header when expanded preference is set', ->
      @createCardboard().then =>
        _.each @getCollapsableHeaderElements(), (element) =>
          expect(element.getHeight() > 0).toBe true

    it 'should show a collapsed header when collapsed preference is set', ->
      @createCardboard('false').then =>
        _.each @getCollapsableHeaderElements(), (element) =>
          expect(element.getHeight()).toBe 0

  describe 'toggle button click', ->
    it 'should collapse header when the header is expanded', ->
      @createCardboard().then =>
        @toggleExpansion().then =>
          _.each @getCollapsableHeaderElements(), (element) =>
            expect(element.getHeight()).toBe 0

    it 'should expand header when the header is collapsed', ->
      @createCardboard('false').then =>
        @toggleExpansion().then =>
          _.each @getCollapsableHeaderElements(), (element) =>
            expect(element.getHeight() > 0).toBe true

  describe 'client metrics', ->
    it 'should log collapse message when toggle button is clicked and header is expanded', ->
      @createCardboard().then =>
        @toggleExpansion().then =>
          expect(@cardboard.plugins[0].getClickActionDescription()).toEqual("Roadmap header expansion toggled from [true] to [false]")

    it 'shouldlog expand message when expand button is clicked and header is collapsed', ->
      @createCardboard('false').then =>
        @toggleExpansion().then =>
          expect(@cardboard.plugins[0].getClickActionDescription()).toEqual("Roadmap header expansion toggled from [false] to [true]")

  describe 'adding a column', ->
    it 'should create expanded header when expanded preference is set', ->
      @createCardboard().then =>
        @clickAddNewButton().then =>
          _.each @getCollapsableHeaderElements(), (element) =>
            expect(element.getHeight() > 0).toBe true

    it 'should create collapsed header when collapsed preference is set', ->
      @createCardboard('false').then =>
        @clickAddNewButton().then =>
          _.each @getCollapsableHeaderElements(), (element) =>
            expect(element.getHeight()).toBe 0
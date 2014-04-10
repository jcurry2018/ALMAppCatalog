Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.nav.Manager'
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.PlanningGridBoard'
]

describe 'Rally.apps.roadmapplanningboard.PlanningGridBoard', ->
  helpers
    createGridboard: (includeTypeNames = true) ->
      config =
        roadmap: @roadmapStore.first()
        timeline: @timelineStore.first()
        context: Rally.environment.getContext()
        modelNames: ['PortfolioItem/Feature']
        renderTo: 'testDiv'

      if includeTypeNames
        config.typeNames =
          child:
            name: 'Feature'

      @gridboard = Ext.create 'Rally.apps.roadmapplanningboard.PlanningGridBoard', config
      @waitForComponentReady(@gridboard)

    typeName: (name) ->
      @click(css: '.add-new a')
      @click(css: '.add-new .rally-textfield-component input').sendKeys name

    addArtifact: (name) ->
      @typeName name
      @click(css: '.add-new .add')

    openCreateEditor: (name) ->
      @typeName name
      @click(css: '.add-new .add-with-details')

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @timelineStore = Deft.Injector.resolve('timelineStore')
    @roadmapStore = Deft.Injector.resolve('roadmapStore')
    @ajax.whenQuerying('TypeDefinition').respondWith Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemFeature')
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith [ Name: 'Feature 1', _ref: '/foobar/123', PreliminaryEstimate : {_refObjectName: 'L'} ]

  afterEach ->
    @gridboard?.destroy()
    Deft.Injector.reset()

  it 'should throw an error if typeNames does not include a child property with a name', ->
    createGridboard = =>
      @createGridboard(false)

    expect(createGridboard).toThrow('typeNames must have a child property with a name')

  it 'should wrap a roadmap planning board', ->
    @createGridboard().then =>
      expect(@gridboard.getGridOrBoard()).toBeTruthy()
      expect(@gridboard.getGridOrBoard().$className).toEqual('Rally.apps.roadmapplanningboard.PlanningBoard')

  it 'should render feedback', ->
    @createGridboard().then =>
      expect(!!@gridboard.down('#feedback')).toBe true

  it 'should have a add new button', ->
    @createGridboard().then =>
      # kludge to get appsdk changes in without breaking this test
      button = @gridboard.down('#expandButton') || @gridboard.down('#new')
      expect(button).toBeDefined()

  describe 'integration', ->
    beforeEach ->
      @editorStub = @stub(Rally.nav.Manager, 'create')
      @createRequest = @ajax.whenCreating('PortfolioItem/Feature').respondWith Name: 'Feature 2'

    it 'should send rankAbove when adding a new feature', ->
      @createGridboard().then =>
        @addArtifact('foo').then =>
          expect(@createRequest).toBeWsapiRequestWith params: { rankAbove: '/foobar/123' }

    it 'should send rankAbove when adding a new feature with details', ->
      @createGridboard().then =>
        @openCreateEditor('foo').then =>
          expect(@editorStub.lastCall.args[1].rankAbove).toBe '/foobar/123'

Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.nav.Manager'
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.PlanningGridBoard'
]

describe 'Rally.apps.roadmapplanningboard.PlanningGridBoard', ->
  helpers
    createPermissionsStub: (config) ->
      @stub Rally.environment.getContext(), 'getPermissions', ->
        isSubscriptionAdmin: ->
          !!config.subAdmin
        isWorkspaceAdmin: ->
          !!config.workspaceAdmin
        isProjectEditor: ->
          !!config.projectEditor

    createGridboard: (expectError = false, context = Rally.environment.getContext()) ->
      @gridboard = Ext.create 'Rally.apps.roadmapplanningboard.PlanningGridBoard',
        roadmap: @roadmapStore.first()
        timeline: @timelineStore.first()
        context: context
        typeName: 'Feature'
        modelNames: ['PortfolioItem/Feature']
        renderTo: 'testDiv'

      @waitForComponentReady(@gridboard)

    typeName: (name) ->
      @click(css: '.add-new button')
      @click(css: '.add-new .rally-textfield-component input').sendKeys name

    addArtifact: (name) ->
      @typeName name
      @click(css: '.add-new .add button')

    openCreateEditor: (name) ->
      @typeName name
      @click(css: '.add-new .add-with-details button')

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @timelineStore = Deft.Injector.resolve('timelineStore')
    @roadmapStore = Deft.Injector.resolve('roadmapStore')
    @ajax.whenQuerying('TypeDefinition').respondWith Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemFeature')
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith [ Name: 'Feature 1', _ref: '/foobar/123', PreliminaryEstimate : {_refObjectName: 'L'} ]

  afterEach ->
    @gridboard.destroy()
    Deft.Injector.reset()

  it 'should wrap a roadmap planning board', ->
    @createGridboard().then =>
      expect(@gridboard.getGridOrBoard()).toBeTruthy()
      expect(@gridboard.getGridOrBoard().$className).toEqual('Rally.apps.roadmapplanningboard.PlanningBoard')

  it 'should render feedback', ->
    @createGridboard().then =>
      expect(!!@gridboard.down('#feedback')).toBe true

  it 'should have a add new button', ->
    @createGridboard().then =>
      expect(!!@gridboard.down('#new')).toBe true

  it 'should set isAdmin on gridboard to true if user is a Sub Admin', ->
    @createPermissionsStub(subAdmin: true)
    @createGridboard().then =>
      expect(@gridboard.getGridOrBoard().isAdmin).toBe true

  it 'should set isAdmin on gridboard to true if user is a WS Admin', ->
    @createPermissionsStub(workspaceAdmin: true)
    @createGridboard().then =>
      expect(@gridboard.getGridOrBoard().isAdmin).toBe true

  it 'should set isAdmin on gridboard to false if user is not a Sub or WS Admin', ->
    @createPermissionsStub(subAdmin: false, workspaceAdmin: false)
    @createGridboard().then =>
      expect(@gridboard.getGridOrBoard().isAdmin).toBe false

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

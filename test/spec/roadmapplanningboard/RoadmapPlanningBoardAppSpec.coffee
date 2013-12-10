Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp',
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
]

describe 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', ->
  helpers
    createApp: (settings = {}, context = {}) ->
      @app = Ext.create 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp',
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
            , context

        settings: settings
        renderTo: 'testDiv'

      @waitForComponentReady(@app.down('container'))

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @ajax.whenQuerying('TypeDefinition').respondWith Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemFeature')
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith []

  afterEach ->
    @app?.destroy()
    Deft.Injector.reset()

  it 'should create a container', ->
    @createApp().then =>
      expect(@app.down('container')).toBeDefined()

  it 'should forward app context to container', ->
    @createApp().then =>
      expect(@app.down('container').getContext().getProject().ObjectID).toBe 123456
Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp'
]

describe 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', ->
  helpers
    createApp: (config) ->
      context = Ext.create 'Rally.app.Context',
        initialValues:
          project:
            ObjectID: 123456

      @container = Ext.create('Ext.container.Container')
      @createPlanningBoardStub = @stub Rally.apps.roadmapplanningboard.RoadmapPlanningBoardController::,
        'createPlanningBoard', () => @container

      @app = Ext.create 'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp',
        context: context
        renderTo: 'testDiv'

      @once
        condition: => @container.rendered

  it 'should create a controller', ->
    @createApp().then =>
      expect(!!@app.controller).toBe true

  it 'should forward app context to controller', ->
    @createApp().then =>
      expect(@app.controller.getContext().getProject().ObjectID).toBe 123456

  it 'should add a container to the app', ->
    @createApp().then =>
      expect(@app.down().getId()).toBe @container.getId()
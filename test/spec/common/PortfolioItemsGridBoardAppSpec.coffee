Ext = window.Ext4 || window.Ext
Ext.require [
  'Rally.data.util.PortfolioItemHelper'
], ->
describe 'Rally.apps.common.PortfolioItemsGridBoardApp', ->
  helpers
    createApp: ->
      Ext.create 'Rally.apps.common.PortfolioItemsGridBoardApp',
        context: Ext.create 'Rally.app.Context',
          initialValues:
            project: Rally.environment.getContext().getProject()
            workspace: Rally.environment.getContext().getWorkspace()
            user: Rally.environment.getContext().getUser()
            subscription: Rally.environment.getContext().getSubscription()
        renderTo: 'testDiv'

    renderApp: ->
      @app = @createApp()
      @app.loadGridBoard = Ext.bind(@app.addGridBoard, @app)
      loadGridBoardSpy = @spy @app, 'loadGridBoard'
      @waitForCallback loadGridBoardSpy

  beforeEach ->
    @theme = Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemTheme')
    @initiative = Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemInitiative')
    @feature = Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemFeature')

    @typeRequest = @ajax.whenQuerying('typedefinition').respondWith [
      @theme
      @initiative
      @feature
    ]

  describe 'PI type picker ', ->
    it 'should have filter configuration using lowest-level PI type', ->
      @renderApp().then =>
        expect(@app.currentType.data._refObjectUUID).toBe @feature._refObjectUUID

    it 'should trigger modeltypeschange event when selection changes', ->
      @renderApp().then =>
        modelChangeStub = @stub()
        @app.gridboard.on('modeltypeschange', modelChangeStub)
        @app.piTypePicker.setValue(Rally.util.Ref.getRelativeUri(@theme._ref))
        expect(modelChangeStub).toHaveBeenCalledOnce()

  describe 'component rendering ', ->
    it 'should show an Add New button', ->
      @renderApp().then =>
        expect(Ext.query('.add-new a.new').length).toBe 1

    it 'should not show an Add New button without proper permissions', ->
      @stub Rally.environment.getContext().getPermissions(), 'isProjectEditor', -> false
      @renderApp().then =>
        expect(Ext.query('.add-new a').length).toBe 0

    it 'shows a filter button', ->
      @renderApp().then =>
        expect(Ext.query('.gridboard-filter-control').length).toBe 1

    it 'shows an owner filter', ->
      @renderApp().then =>
        expect(Ext.query('.rally-owner-filter').length).toBe 1

    it 'shows a portfolio item type picker', ->
      @renderApp().then =>
        expect(Ext.query('.portfolio-item-type-combo').length).toBe 1


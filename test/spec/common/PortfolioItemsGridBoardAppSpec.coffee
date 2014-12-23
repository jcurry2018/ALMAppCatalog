Ext = window.Ext4 || window.Ext
Ext.require [
  'Rally.data.util.PortfolioItemHelper'
], ->
describe 'Rally.apps.common.PortfolioItemsGridBoardApp', ->
  helpers
    createApp: (config = {}) ->
      Ext.create 'Rally.apps.common.PortfolioItemsGridBoardApp',
        Ext.apply
          context: Ext.create 'Rally.app.Context',
            initialValues:
              project: Rally.environment.getContext().getProject()
              workspace: Rally.environment.getContext().getWorkspace()
              user: Rally.environment.getContext().getUser()
          renderTo: 'testDiv'
        , config

    renderApp: (config) ->
      @app = @createApp(config)
      @waitForComponentReady @app

  beforeEach ->
    @piHelper = new Helpers.PortfolioItemGridBoardHelper @
    @piHelper.stubPortfolioItemRequests()

  describe 'PI type picker ', ->
    it 'should have filter configuration using lowest-level PI type', ->
      @renderApp().then =>
        expect(@app.currentType.data._refObjectUUID).toBe @piHelper.feature._refObjectUUID

    it 'should trigger modeltypeschange event when selection changes', ->
      @renderApp().then =>
        modelChangeStub = @stub()
        @app.gridboard.on('modeltypeschange', modelChangeStub)
        @app.piTypePicker.setValue(Rally.util.Ref.getRelativeUri(@piHelper.theme._ref))
        expect(modelChangeStub).toHaveBeenCalledOnce()

    it 'should apply custom filter when selection changes in grid mode', ->
      @renderApp(toggleState: 'grid').then =>
        applyCustomFilterSpy = @spy @app.gridboard, 'applyCustomFilter'
        @app.piTypePicker.setValue(Rally.util.Ref.getRelativeUri(@piHelper.theme._ref))
        expect(applyCustomFilterSpy.callCount).toBe 1
        expect(applyCustomFilterSpy.calledWith(types: @app.modelNames)).toBe true

    it 'should load gridboard when selection changes in board mode', ->
      @renderApp(toggleState: 'board').then =>
        loadGridBoardSpy = @spy @app, 'loadGridBoard'
        @app.piTypePicker.setValue(Rally.util.Ref.getRelativeUri(@piHelper.theme._ref))
        expect(loadGridBoardSpy.callCount).toBe 1
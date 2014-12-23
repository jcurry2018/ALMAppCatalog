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
        renderTo: 'testDiv'

    renderApp: ->
      @app = @createApp()
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
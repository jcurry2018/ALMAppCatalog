Ext = window.Ext4 || window.Ext
Ext.require [
  'Rally.data.util.PortfolioItemHelper'
], ->
describe 'Rally.apps.common.PortfolioItemsGridBoardApp', ->
  helpers
    createApp: (config = {}) ->
      Ext.create 'Ext.Container',
        id: 'content'
        items: [
          xtype: 'container'
          cls: 'titlebar'
          items: [
            cls: 'dashboard-timebox-container'
          ]
        ]
        renderTo: 'testDiv'

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

  afterEach ->
    @app?.destroy()

  describe 'PI type picker ', ->
    helpers
      changeType: ->
        addGridBoardSpy = @spy @app, 'addGridBoard'
        @app.piTypePicker.setValue(Rally.util.Ref.getRelativeUri(@piHelper.theme._ref))
        @waitForCallback addGridBoardSpy

    _.each ['board', 'grid'], (toggleState) =>
      describe "in #{toggleState} mode", ->
        beforeEach ->
          @renderApp toggleState: toggleState

        it 'should have filter configuration using lowest-level PI type', ->
          expect(@app.currentType.data._refObjectUUID).toBe @piHelper.feature._refObjectUUID

        describe 'on type change', ->
          it 'should trigger modeltypeschange event when selection changes', ->
            modelChangeStub = @stub()
            @app.gridboard.on('modeltypeschange', modelChangeStub)
            @changeType().then =>
              expect(modelChangeStub).toHaveBeenCalledOnce()

          it 'should load a new gridboard when selection changes', ->
            @changeType().then =>
              expect(@app.gridboard.modelNames).toEqual [@piHelper.theme.TypePath]

          it 'should not destroy the type picker', ->
            typePicker = @app.piTypePicker
            destroyStub = @stub()
            typePicker.on 'destroy', destroyStub

            @changeType().then =>
              expect(typePicker.isVisible()).toBe true
              expect(destroyStub).not.toHaveBeenCalled()
              expect(@app.piTypePicker).toBe typePicker

    it 'should destroy the piTypePicker when the app is destroyed', ->
      @renderApp().then =>
        typePicker = @app.piTypePicker
        @spy typePicker, 'destroy'
        @app.destroy()
        expect(typePicker.destroy).toHaveBeenCalledOnce()
        expect(@app.piTypePicker).toBeUndefined()

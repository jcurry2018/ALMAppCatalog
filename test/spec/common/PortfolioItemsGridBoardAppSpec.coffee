Ext = window.Ext4 || window.Ext
Ext.require [
  'Rally.data.util.PortfolioItemHelper'
], ->
describe 'Rally.apps.common.PortfolioItemsGridBoardApp', ->
  helpers
    getExtContext: () ->
      Ext.create 'Rally.app.Context',
                  initialValues:
                    project: Rally.environment.getContext().getProject()
                    workspace: Rally.environment.getContext().getWorkspace()
                    user: Rally.environment.getContext().getUser()
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
          context: @getExtContext()
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

  describe 'PI App', ->
    it 'should not modify gridStoreConfig', ->
      @renderApp({}).then =>
        secondInstance = Ext.create('Rally.app.GridBoardApp', {
          modelNames: ['User']
          context: @getExtContext()
          renderTo: 'testDiv'
        })
        expect(secondInstance.gridStoreConfig).toEqual({})

  describe 'PI type picker ', ->
    helpers
      changeType: ->
        addGridBoardSpy = @spy @app, 'addGridBoard'
        @app.piTypePicker.setValue(Rally.util.Ref.getRelativeUri(@piHelper.theme._ref))
        @waitForCallback addGridBoardSpy

    describe 'render location controlled with piTypePickerConfig', ->
      helpers
        renderAppWithPiPickerInGridHeader: (renderInGridHeader)->
          config = {}
          if renderInGridHeader? then config.piTypePickerConfig = {renderInGridHeader: renderInGridHeader}
          return @renderApp(config)

      it 'should render to the left in the grid header when configured with \'renderInGridHeader\':true ', ->
        @renderAppWithPiPickerInGridHeader(true).then =>
          expect(@app.gridboard.getHeader?().getLeft?().contains?(@app.piTypePicker)).toBeTruthy()

      it 'should render to dashboard title when configured with \'renderInGridHeader\':false ', ->
        @renderAppWithPiPickerInGridHeader(false).then =>
          expect(@app.gridboard.getHeader?().getRight?().contains?(@app.piTypePicker)).toBeFalsy()
          expect(Ext.query('#content .titlebar .dashboard-timebox-container')[0].contains(@app.piTypePicker.getEl().dom)).toBeTruthy()

      it 'should render to the dashboard title by default ', ->
        @renderAppWithPiPickerInGridHeader().then =>
          expect(@app.gridboard.getHeader?().getRight?().contains?(@app.piTypePicker)).toBeFalsy()
          expect(Ext.query('#content .titlebar .dashboard-timebox-container')[0].contains(@app.piTypePicker.getEl().dom)).toBeTruthy()


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

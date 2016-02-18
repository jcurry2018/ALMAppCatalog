Ext = window.Ext4 || window.Ext
Ext.require [
  'Rally.data.util.PortfolioItemHelper'
  'Rally.app.Context'
]
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

    stubFeatureToggle: (toggles, value = true) ->
      stub = @stub(Rally.app.Context.prototype, 'isFeatureEnabled');
      stub.withArgs(toggle).returns(value) for toggle in toggles
      stub

    changeType: ->
      addGridBoardSpy = @spy @app, 'addGridBoard'
      @app.piTypePicker.setValue(Rally.util.Ref.getRelativeUri(@piHelper.theme._ref))
      @waitForCallback addGridBoardSpy

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
        expect(secondInstance.getGridStoreConfig()).toEqual({})

  describe 'PI type picker ', ->
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

  describe 'filtering panel plugin', ->
    helpers
      getPlugin: (filterptype='rallygridboardinlinefiltercontrol') ->
        gridBoard = @app.down 'rallygridboard'
        _.find gridBoard.plugins, (plugin) ->
          plugin.ptype == filterptype

    it 'should have the old filter component by default', ->
      @renderApp().then =>
        expect(@getPlugin('rallygridboardcustomfiltercontrol')).toBeDefined()

    it 'should use rallygridboard filtering plugin', ->
      @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
      @renderApp().then =>
        expect(@getPlugin()).toBeDefined()

    it 'should set inline false when a full page app', ->
      @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
      @renderApp().then =>
        expect(@getPlugin().inline).toBe false

    it 'should set inline false when NOT a full page app', ->
      @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
      @renderApp(isFullPageApp: false).then =>
        expect(@getPlugin().inline).toBe false

    describe 'quick filters', ->

      it 'should add filters for search and owner', ->
        @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
        @renderApp().then =>
          config = @getPlugin().inlineFilterButtonConfig.inlineFilterPanelConfig.quickFilterPanelConfig
          expect(config.defaultFields[0]).toBe 'ArtifactSearch'
          expect(config.defaultFields[1]).toBe 'Owner'
          expect(config.defaultFields.length).toBe 2

  describe 'shared view plugin', ->
    helpers
      getPlugin: ->
        gridBoard = @app.down 'rallygridboard'
        _.find gridBoard.plugins, (plugin) ->
          plugin.ptype == 'rallygridboardsharedviewcontrol'

    it 'should not have shared view plugin if the toggle is off', ->
      @renderApp().then =>
        gridBoard = @app.down 'rallygridboard'
        expect(@getPlugin()).not.toBeDefined()

    it 'should configure gridboard with sharedViewAdditionalCmps', ->
      @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
      @renderApp().then =>
        expect(@app.gridboard.sharedViewAdditionalCmps.length).toBe 1
        expect(@app.gridboard.sharedViewAdditionalCmps[0]).toBe @app.piTypePicker

    it 'should use rallygridboard shared view plugin if toggled on', ->
      @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
      @renderApp().then =>
        plugin = @getPlugin()
        expect(plugin).toBeDefined()
        expect(plugin.sharedViewConfig.stateful).toBe true
        expect(plugin.sharedViewConfig.stateId).toBe @app.getContext().getScopedStateId('portfolio-items-shared-view')
        expect(plugin.sharedViewConfig.defaultViews).toBeDefined()
        expect(plugin.sharedViewConfig.suppressViewNotFoundNotification).not.toBeDefined()
        expect(plugin.additionalFilters.length).toBe 1
        expect(plugin.additionalFilters[0].value).toBe '"piTypePicker":"' + @app.piTypePicker.getRecord().get('_refObjectUUID') + '"'

    it 'should load gridboard with suppressViewNotFoundNotification set to true after PI type change', ->
      @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
      @renderApp().then =>
        @stub(@getPlugin().controlCmp, 'getSharedViewParam').returns true
        @changeType()
        @once
          condition: => @getPlugin().sharedViewConfig.suppressViewNotFoundNotification

    it 'sets current view on viewchange', ->
      @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
      @renderApp().then =>
        loadSpy = @spy(@app, 'loadGridBoard')
        @app.gridboard.fireEvent 'viewchange'
        expect(loadSpy).toHaveBeenCalledOnce()
        expect(@app.down('#gridBoard')).toBeDefined()

    it 'should add correct rank field when manually ranked', ->
      @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
      context = Ext.create('Rally.app.Context',
        initialValues:
          workspace:
            WorkspaceConfiguration:
              DragDropRankingEnabled: false
      )
      @renderApp({context: context}).then =>
        defaultViews =  @getPlugin().sharedViewConfig.defaultViews
        expect(Ext.JSON.decode(defaultViews[0].Value, true).columns[0].dataIndex).toBe 'Rank'

    it 'should add correct rank field when dnd ranked', ->
      @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
      context = Ext.create('Rally.app.Context',
        initialValues:
          workspace:
            WorkspaceConfiguration:
              DragDropRankingEnabled: true
      )
      @renderApp({context: context}).then =>
        defaultViews =  @getPlugin().sharedViewConfig.defaultViews
        expect(Ext.JSON.decode(defaultViews[0].Value, true).columns[0].dataIndex).toBe 'DragAndDropRank'

    it 'should enableUrlSharing when isFullPageApp is true', ->
      @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
      @renderApp(
        isFullPageApp: true
      ).then =>
        expect(@getPlugin().sharedViewConfig.enableUrlSharing).toBe true

    it 'should NOT enableUrlSharing when isFullPageApp is false', ->
      @stubFeatureToggle ['S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN'], true
      @renderApp(
        isFullPageApp: false
      ).then =>
        expect(@getPlugin().sharedViewConfig.enableUrlSharing).toBe false

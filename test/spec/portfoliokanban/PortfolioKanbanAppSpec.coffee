Ext = window.Ext4 || window.Ext
Ext.require [
  'Ext.Array'
  'Rally.app.Context'
  'Rally.Message'
  'Ext.Element'
  'Rally.util.Ref'
  'Rally.apps.portfoliokanban.PortfolioKanbanApp'
  'Rally.data.util.PortfolioItemHelper'
]

describe 'Rally.apps.portfoliokanban.PortfolioKanbanApp', ->
  helpers
    _createApp: (config, isFullPageApp = false) ->
      @app = Ext.create 'Rally.apps.portfoliokanban.PortfolioKanbanApp', Ext.merge
        context: Ext.create 'Rally.app.Context',
          initialValues:
            project: Rally.environment.getContext().getProject()
            workspace: Rally.environment.getContext().getWorkspace()
            user: Rally.environment.getContext().getUser()
            subscription: Rally.environment.getContext().getSubscription(),
        renderTo: 'testDiv'
        height: 500
        isFullPageApp: isFullPageApp
      , config

      @waitForComponentReady @app

    _getTextsForElements: (cssQuery) ->
      Ext.Array.map(@app.getEl().query(cssQuery), (el) -> el.innerHTML).join('__')

    _clickAndWaitForVisible: (fieldName) ->
      @click(css: '.progress-bar-container.field-' + fieldName).then =>
        @waitForVisible(css: '.percentDonePopover')

    getFeatureData: (config) ->
      _.merge
        ObjectID: 878
        _ref: '/portfolioitem/feature/878'
        FormattedID: 'F1'
        Name: 'Name of first PI'
        Owner:
          _ref: '/user/1'
          _refObjectName: 'Name of Owner'
        State: '/feature/state/1'
      , config

    waitForAppReady: ->
      readyStub = @stub()
      Rally.environment.getMessageBus().subscribe Rally.Message.piKanbanBoardReady, readyStub
      @waitForCallback readyStub

    stubFeatureToggle: (toggles, value = true) ->
      stub = @stub(Rally.app.Context.prototype, 'isFeatureEnabled');
      stub.withArgs(toggle).returns(value) for toggle in toggles
      stub

  beforeEach ->
    @piHelper = new Helpers.PortfolioItemGridBoardHelper @
    @piHelper.stubPortfolioItemRequests()

    @featureStates = [ _type: 'State', Name: 'FeatureColumn1', _ref: '/feature/state/1', WIPLimit: 4 ]
    @initiativeStates = [
      { _type: 'State', Name: 'InitiativeColumn1', _ref: '/initiative/state/1', WIPLimit: 1 }
      { _type: 'State', Name: 'InitiativeColumn2', _ref: '/initiative/state/2', WIPLimit: 2 }
    ]
    @themeStates = [
      { _type: 'State', Name: 'ThemeColumn1', _ref: '/theme/state/1', WIPLimit: 1 }
      { _type: 'State', Name: 'ThemeColumn2', _ref: '/theme/state/2', WIPLimit: 2 }
      { _type: 'State', Name: 'ThemeColumn3', _ref: '/theme/state/3', WIPLimit: 2 }
    ]

    @ajax.whenQuerying('state').respondWith @featureStates

  afterEach ->
    @app?.down('rallyfilterinfo')?.tooltip?.destroy()
    @app?.destroy()

  it 'shows help component', ->
    @_createApp().then =>
      expect(@app.gridboard).toHaveHelpComponent()

  it 'does not show help component when is full page app', ->
    @_createApp({}, true).then =>
      expect(@app.gridboard).not.toHaveHelpComponent()

  it 'creates columns from states', ->
    @ajax.whenQuerying('state').respondWith @initiativeStates

    @_createApp(settings: type: Rally.util.Ref.getRelativeUri(@piHelper.initiative._ref)).then =>
      expect(@app.gridboard.getGridOrBoard().getColumns().length).toEqual @initiativeStates.length + 1

  it 'shows message if no states are found', ->
    @ajax.whenQuerying('state').respondWith()

    @_createApp().then =>
      expect(@app.el.dom.textContent).toContain "This Type has no states defined."

  it 'displays filter icon', ->
    @_createApp().then =>
      expect(@app.getEl().down('.filterInfo') instanceof Ext.Element).toBeTruthy()

  it 'does not display a filter icon when isFullPageApp', ->
    @_createApp(null, true).then =>
      expect(@app.getEl().down('.filterInfo')).toBeFalsy()

  it 'shows project setting label if following a specific project scope', ->
    @_createApp(settings: project: '/project/431439').then =>
      @app.down('rallyfilterinfo').tooltip.show()
      expect(Ext.query('.filterInfoTooltip')[0].textContent).toContain 'Project 1'

  it 'shows "Following Global Project Setting" in project setting label if following global project scope', ->
    @ajax.whenQuerying('project').respondWith [Name: 'Test Project', _ref: '/project/2']

    @_createApp().then =>
      @app.down('rallyfilterinfo').tooltip.show()
      expect(Ext.query('.filterInfoTooltip')[0].textContent).toContain 'Following Global Project Setting'

  it 'shows Discussion on Card', ->
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith [ @getFeatureData Summary: Discussion: Count: 1 ]
    @_createApp().then =>
      expect(@app.gridboard.getGridOrBoard().getColumns()[1].getCards()[0].getEl().down('.status-field.Discussion')).not.toBeNull()

  it 'displays mandatory fields on the cards', ->
    feature = @getFeatureData()
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith [feature]

    @_createApp().then =>
      expect(@_getTextsForElements('.field-content')).toContain feature.Name
      expect(@_getTextsForElements('.id')).toContain feature.FormattedID
      expect(@app.getEl().query('.Owner .rui-field-value')[0].title).toContain feature.Owner._refObjectName

  it 'should display an error message if you do not have RPM turned on ', ->
    Rally.environment.getContext().context.subscription.Modules = []
    loadSpy = @spy Rally.data.util.PortfolioItemHelper, 'loadTypeOrDefault'

    @_createApp().then =>
      expect(loadSpy.callCount).toBe 0
      expect(@app.getEl().dom.innerHTML).toContain 'You do not have RPM enabled for your subscription'

  it 'should use rallygridboard filter control', ->
    @_createApp().then =>
      gridBoard = @app.down 'rallygridboard'
      plugin = _.find gridBoard.plugins, (plugin) ->
        plugin.ptype == 'rallygridboardcustomfiltercontrol'
      expect(plugin).toBeDefined()
      expect(plugin.filterControlConfig.stateful).toBe true
      expect(plugin.filterControlConfig.stateId).toBe @app.getContext().getScopedStateId('portfolio-kanban-custom-filter-button')

      expect(plugin.showOwnerFilter).toBe true
      expect(plugin.ownerFilterControlConfig.stateful).toBe true
      expect(plugin.ownerFilterControlConfig.stateId).toBe @app.getContext().getScopedStateId('portfolio-kanban-owner-filter')


# These are commented out due to DE22270.
# Once DE22270 is fixed, uncomment these and they should pass!
# Changes to the GridBoardCustomFilterControl caused this app to start refresh twice when the type changes, which causes the tests to fail.
# Due to how the tests are wired up, they only failed once we added the type picker to other pages(S69900).
# NOTE: these only seem to fail when the whole test suite is run.
#
#  describe 'when the type is changed', ->
#    it 'should reload the gridboard', ->
#      @_createApp().then =>
#        loadGridBoardSpy = @spy @app, 'loadGridBoard'
#        @app.piTypePicker.setValue(Rally.util.Ref.getRelativeUri(@piHelper.theme._ref))
#        @waitForCallback(loadGridBoardSpy).then =>
#          expect(loadGridBoardSpy).toHaveBeenCalledOnce()
#
#    beforeEach ->
#      @ajax.whenQuerying('state').respondWith(@initiativeStates)
#
#      @_createApp(settings: type: Rally.util.Ref.getRelativeUri(@piHelper.initiative._ref)).then =>
#        @ajax.whenQuerying('state').respondWith(@themeStates)
#        @app.piTypePicker.setValue(Rally.util.Ref.getRelativeUri(@piHelper.theme._ref))
#        @waitForAppReady()
#
#    it 'should update the gridboard types', ->
#      expect(@app.gridboard.types).toEqual [ @piHelper.theme.TypePath ]
#
#    it 'should refresh the gridboard with columns matching the states of the new type', ->
#      expect(@app.gridboard.getColumns().length).toBe @themeStates.length + 1
#      _.each @app.gridboard.getColumns().slice(1), (column, index) =>
#        expect(column.value).toBe '/theme/state/' + (index + 1)
#
#    it 'should display policy header if Show Policies previously checked', ->
#      policyCheckbox = this.app.gridboard.getPlugin('boardPolicyDisplayable')
#      expect(policyCheckbox.isChecked()).toBe false
#      expect(_.every(_.invoke(Ext.ComponentQuery.query('#policyHeader'), 'isVisible', true))).toBe false
#      @click(css: '.agreements-checkbox input').then =>
#        expect(policyCheckbox.isChecked()).toBe true
#        afterColumnRenderStub = @stub()
#        @app.gridboard.getGridOrBoard().on('aftercolumnrender', afterColumnRenderStub)
#        @app.piTypePicker.setValue(Rally.util.Ref.getRelativeUri(@piHelper.feature._ref))
#        @waitForCallback(afterColumnRenderStub).then =>
#          expect(_.every(_.invoke(Ext.ComponentQuery.query('#policyHeader'), 'isVisible', true))).toBe true

  describe 'settings', ->
    it 'should contain a query setting', ->
      @_createApp().then =>
        expect(@app).toHaveSetting 'query'

    it 'should use query setting to filter board', ->
      @_createApp(
        settings:
          query: '(Name = "abc")'
      ).then =>
        expect(@getAppStore()).toHaveFilter 'Name', '=', 'abc'

    it 'should set settingsScope to project if isFullPageApp true', ->
      @_createApp(
        isFullPageApp: true
      ).then =>
        expect(@app.settingsScope).toBe 'project'

    it 'should set settingsScope to app if isFullPageApp false', ->
      @_createApp(
        isFullPageApp: false
      ).then =>
        expect(@app.settingsScope).toBe 'app'

    it 'should pass app scoping information to gridboard', ->
      @_createApp().then =>
        expect(@app.gridboard.getGridOrBoard().getContext()).toBe @app.getContext()

    it 'should NOT have the rowSettings field', ->
      @stubFeatureToggle(['S79575_ADD_SWIMLANES_TO_PI_KANBAN'], false)
      @_createApp().then =>
        expect(_.find(@app.getSettingsFields(), {xtype: 'rowsettingsfield'})).not.toBeDefined()

    it 'should have the rowSettings field', ->
      @stubFeatureToggle(['S79575_ADD_SWIMLANES_TO_PI_KANBAN'], true)
      @_createApp().then =>
        expect(_.find(@app.getSettingsFields(), {xtype: 'rowsettingsfield'})).toBeDefined()

    it 'adds the rowConfig property to the boardConfig', ->
      @stubFeatureToggle(['S79575_ADD_SWIMLANES_TO_PI_KANBAN'], true)
      @_createApp(
        settings:
          showRows: true
          rowsField: 'Owner'
      ).then =>
        expect(@app.gridboard.getGridOrBoard().config.rowConfig.field).toBe 'Owner'

    it 'does NOT add the rowConfig property to the boardConfig', ->
      @stubFeatureToggle(['S79575_ADD_SWIMLANES_TO_PI_KANBAN'], false)
      @_createApp(
        settings:
          showRows: true
          rowsField: 'Owner'
      ).then =>
        expect(@app.gridboard.getGridOrBoard().config.rowConfig).toBeNull()

    helpers
      getAppStore: ->
        @app.gridboard.getGridOrBoard().getColumns()[0].store

    describe 'field picker', ->
      it 'should show', ->
        @_createApp().then =>
          expect(@app.down('#fieldpickerbtn').isVisible()).toBe true

      it 'should have use the legacy field setting if available', ->
        @_createApp(settings: fields: 'Field1,Field2').then =>
          expect(@app.down('rallygridboard').getGridOrBoard().columnConfig.fields).toEqual ['Field1','Field2']

  describe 'sizing', ->
    it 'should set an initial gridboard height', ->
      @_createApp().then =>
        expect(@app.down('rallygridboard').getHeight()).toBe @app.getHeight()

    it 'should update the board height', ->
      @_createApp().then =>
        gridBoard = @app.down 'rallygridboard'
        currentHeight = gridBoard.getHeight()
        @app.setHeight @app.getHeight() + 10
        expect(gridBoard.getHeight()).toBe currentHeight + 10

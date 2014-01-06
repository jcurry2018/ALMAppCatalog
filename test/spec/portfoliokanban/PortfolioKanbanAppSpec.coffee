Ext = window.Ext4 || window.Ext

describe 'Rally.apps.portfoliokanban.PortfolioKanbanApp', ->

  helpers
    _createApp: (settings) ->
      globalContext = Rally.environment.getContext()
      context = Ext.create 'Rally.app.Context',
        initialValues:
          project:globalContext.getProject()
          workspace:globalContext.getWorkspace()
          user:globalContext.getUser()
          subscription:globalContext.getSubscription()

      options =
        context: context,
        renderTo: 'testDiv'

      options.settings = settings if settings?

      @app = Ext.create('Rally.apps.portfoliokanban.PortfolioKanbanApp', options)

      @waitForComponentReady @app

    _getTextsForElements: (cssQuery) ->
      Ext.Array.map(@app.getEl().query(cssQuery), (el) -> el.innerHTML).join('__')

    _createAppAndWaitForVisible: (callback) ->
      @_createApp(project: '/project/431439')
      @waitForVisible(css: '.progress-bar-container.field-PercentDoneByStoryCount').then =>
        callback()

    _clickAndWaitForVisible: (fieldName) ->
      @click(css: '.progress-bar-container.field-' + fieldName).then =>
        @waitForVisible(css: '.percentDonePopover')


  beforeEach ->
    Rally.environment.getContext().context.subscription.Modules = ['Rally Portfolio Manager']

    @theme = Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemTheme')
    @initiative = Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemInitiative')
    @feature = Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemFeature')

    @typeRequest = @ajax.whenQuerying('typedefinition').respondWith [
      @feature
      @initiative
      @theme
    ]

    @ajax.whenQuerying('state').respondWith [
      '_type': "State"
      'Name': "Column1"
      '_ref': '/state/1'
      'WIPLimit': 4
    ]

  afterEach ->
    if @app?
      if @app.down('rallyfilterinfo')?.tooltip?
        @app.down('rallyfilterinfo').tooltip.destroy()

      @app.destroy()

  it 'should create popover when the progress bar is clicked', ->
    feature =
      ObjectID: 878
      _ref: '/portfolioitem/feature/878'
      FormattedID: 'F1'
      Name: 'Name of first PI'
      Owner:
        _ref: '/user/1'
        _refObjectName: 'Name of Owner'
      State: '/state/1'
      Summary:
        Discussion:
          Count: 1

    @ajax.whenQuerying('PortfolioItem/Feature').respondWith [feature]

    @_createAppAndWaitForVisible =>
      @_clickAndWaitForVisible('PercentDoneByStoryCount').then =>
        expect(Ext.select('.percentDonePopover').elements.length).toEqual(1)

  it 'shows help component', ->
    @_createApp().then =>
      expect(@app).toHaveHelpComponent()

  it 'should show an Add New button', ->
    @_createApp().then =>
      expect(Ext.query('.add-new button').length).toBe 1

  it 'shows ShowPolicies checkbox', ->
    @_createApp().then =>
      expect(@app.down('#header').el.down('input[type="button"]')).toHaveCls 'showPoliciesCheckbox'

  it 'creates columns from states', ->
    @ajax.whenQuerying('state').respondWith([
      {
        '_type': "State"
        'Name': "Column1"
        '_ref': '/state/1'
        'WIPLimit': 4
      },
      {
        '_type': "State"
        'Name': "Column2"
        '_ref': '/state/2'
        'WIPLimit': 3
      }
    ])

    @_createApp().then =>
      expect(@app.cardboard.getColumns().length).toEqual 3

  it 'shows message if no states are found', ->
    @ajax.whenQuerying('state').respondWith()

    @_createApp().then =>
      expect(@app.el.dom.textContent).toContain "This Type has no states defined."

  it 'displays filter icon', ->
    @_createApp().then =>
      expect(@app.getEl().down('.filterInfo') instanceof Ext.Element).toBeTruthy()

  it 'shows project setting label if following a specific project scope', ->
    @_createApp(
      project: '/project/431439'
    ).then =>
      @app.down('rallyfilterinfo').tooltip.show()

      tooltipContent = Ext.get Ext.query('.filterInfoTooltip')[0]

      expect(tooltipContent.dom.textContent).toContain 'Project'
      expect(tooltipContent.dom.textContent).toContain 'Project 1'

  it 'shows "Following Global Project Setting" in project setting label if following global project scope', ->
    @ajax.whenQuerying('project').respondWith([
      {
        Name: 'Test Project'
        '_ref': '/project/2'
      }
    ])

    @_createApp().then =>
      @app.down('rallyfilterinfo').tooltip.show()

      tooltipContent = Ext.get Ext.query('.filterInfoTooltip')[0]

      expect(tooltipContent.dom.textContent).toContain 'Following Global Project Setting'

  it 'shows Discussion on Card', ->
    feature =
      ObjectID: 878
      _ref: '/portfolioitem/feature/878'
      FormattedID: 'F1'
      Name: 'Name of first PI'
      Owner:
        _ref: '/user/1'
        _refObjectName: 'Name of Owner'
      State: '/state/1'
      Summary:
        Discussion:
          Count: 1

    @ajax.whenQuerying('PortfolioItem/Feature').respondWith [feature]

    @_createApp().then =>
      expect(@app.cardboard.getColumns()[1].getCards()[0].getEl().down('.status-field.Discussion')).not.toBeNull()

  it 'displays mandatory fields on the cards', ->
    feature =
      ObjectID: 878
      _ref: '/portfolioitem/feature/878'
      FormattedID: 'F1'
      Name: 'Name of first PI'
      Owner:
        _ref: '/user/1'
        _refObjectName: 'Name of Owner'
      State: '/state/1'

    @ajax.whenQuerying('PortfolioItem/Feature').respondWith [feature]

    @_createApp().then =>
      expect(@_getTextsForElements('.field-content')).toContain feature.Name
      expect(@_getTextsForElements('.id')).toContain feature.FormattedID
      expect(@app.getEl().query('.Owner .rui-field-value')[0].title).toContain feature.Owner._refObjectName

  it 'creates loading mask with unique id', ->
    @_createApp().then =>
      expect(@app.getMaskId()).toBe('btid-portfolio-kanban-board-load-mask-' + @app.id)

  it 'should display an error message if you do not have RPM turned on ', ->
    Rally.environment.getContext().context.subscription.Modules = []
    loadSpy = @spy Rally.data.util.PortfolioItemHelper, 'loadTypeOrDefault'

    @_createApp().then =>
      expect(loadSpy.callCount).toBe 0
      expect(@app.down('#bodyContainer').getEl().dom.innerHTML).toContain 'You do not have RPM enabled for your subscription'

  describe 'settings', ->
    it 'should contain a query setting', ->
      @_createApp().then =>
        expect(@app).toHaveSetting 'query'

    it 'should use query setting to filter board', ->
      @_createApp(
        query: '(Name = "abc")'
      ).then =>
        expect(@getAppStore()).toHaveFilter 'Name', '=', 'abc'

    it 'should contain a type setting', ->
      @_createApp().then =>
        expect(@app).toHaveSetting 'type'

    it 'should use type setting to filter board', ->
      @_createApp(
        type: Rally.util.Ref.getRelativeUri(@initiative._ref)
      ).then =>
        expect(@typeRequest).toBeWsapiRequestWith
          filters: [
            property: 'ObjectID', operator: '=', value: @initiative.ObjectID
          ]

    it 'loads type with ordinal of 1 if no type setting is provided', ->
      @_createApp().then =>
        expect(@getAppStore()).toHaveFilter 'PortfolioItemType', '=', Rally.util.Ref.getRelativeUri(@feature._ref)

    it 'should have a project setting', ->
      @_createApp().then =>
        expect(@app).toHaveSetting 'project'

    it 'should pass app scoping information to cardboard', ->
      @_createApp().then =>
        expect(@app.cardboard.getContext()).toBe @app.getContext()

    it 'should have a project setting', ->
      @_createApp().then =>
        expect(@app).toHaveSetting 'fields'

    helpers
      getAppStore: ->
        @app.cardboard.getColumns()[0].store
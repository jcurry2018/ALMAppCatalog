Ext = window.Ext4 || window.Ext

describe 'Rally.apps.iterationplanningboard.IterationPlanningBoardApp', ->
  helpers
    createApp: (options = {}) ->
      @iterationData = options.iterationData || Helpers.TimeboxDataCreatorHelper.createTimeboxData(options)

      @ajax.whenQuerying('iteration').respondWith(@iterationData)

      @app = Ext.create 'Rally.apps.iterationplanningboard.IterationPlanningBoardApp',
        context: Ext.create 'Rally.app.Context',
          initialValues:
            project:
              _ref: @iterationData[0].Project._ref
            subscription: Rally.environment.getContext().getSubscription()
            workspace: Rally.environment.getContext().getWorkspace()
        renderTo: 'testDiv'

      @waitForComponentReady @app

    createAppWithBacklogData: ->
      userStoryRecord = @mom.getRecord 'userstory',
        emptyCollections: true
        values:
          Iteration: null

      defectRecord = @mom.getRecord 'defect',
        emptyCollections: true
        values:
          Iteration: null

      @ajax.whenQuerying('artifact').respondWith([userStoryRecord.data, defectRecord.data])

      @createApp()

    filterByBacklogCustomSearchQuery: (query) ->
      searchField = @getColumns()[0].getColumnHeader().down('rallysearchfield')
      searchStub = @stub()
      searchField.on 'search', searchStub, @, single: true

      @click(searchField.getEl().down('input')).then (el) =>
        el.sendKeys(query).then =>
          @waitForCallback searchStub

    getColumns: ->
      @app.gridboard.getGridOrBoard().getColumns()

  beforeEach ->
    @ajax.whenQuerying('artifact').respondWith()

  afterEach ->
    @app?.destroy()

  it 'does not show add new or manage iterations when user is not a project editor', ->
    @stub(Rally.auth.UserPermissions.prototype, 'isProjectEditor').returns false

    @createApp().then =>
      expect(@app.down('#header').down 'rallyaddnew').toBeNull()
      expect(@app.down('#header').down 'rallybutton[text=Manage Iterations]').toBeNull()

  it 'should allow managing iterations when user is a project editor and is hs sub', ->
    Rally.test.mock.env.Global.setupEnvironment
      subscription:
        SubscriptionType: 'HS_1'

    @stub(Rally.auth.UserPermissions.prototype, 'isProjectEditor').returns true
    manageIterationsStub = @stub(Rally.nav.Manager, 'manageIterations')

    @createApp().then =>
      manageButton = @app.down('#header').down 'rallybutton[text=Manage Iterations]'
      expect(manageButton).not.toBeNull()
      Rally.test.fireEvent(manageButton, 'click')
      expect(manageIterationsStub.callCount).toBe 1
      expect(manageIterationsStub.getCall(0).args[0]).toEqual @app.getContext()

  it 'fires contentupdated event after board load', ->
    contentUpdatedHandlerStub = @stub()

    @createApp().then =>
      @app.on('contentupdated', contentUpdatedHandlerStub)
      @app.gridboard.fireEvent('load')

      expect(contentUpdatedHandlerStub).toHaveBeenCalledOnce()

  it 'should remove all cards when submitting a search in the backlog column', ->
    @createAppWithBacklogData().then =>
      backlogColumn = @getColumns()[0]
      clearCardsSpy = @spy(backlogColumn, 'clearCards')

      @filterByBacklogCustomSearchQuery('A').then =>
        expect(clearCardsSpy).toHaveBeenCalled()

  it 'should have a default card fields setting', ->
    @createApp().then =>
      expect(@app.getSetting('cardFields')).toBe 'Parent,Tasks,Defects,Discussion,PlanEstimate'

  it 'should use rallygridboard custom filter control', ->
    @createApp().then =>
      gridBoard = @app.down 'rallygridboard'
      plugin = _.find gridBoard.plugins, (plugin) ->
        plugin.ptype == 'rallygridboardcustomfiltercontrol'
      expect(plugin).toBeDefined()
      expect(plugin.filterControlConfig.stateful).toBe true
      expect(plugin.filterControlConfig.stateId).toBe @app.getContext().getScopedStateId('iteration-planning-custom-filter-button')

      expect(plugin.showOwnerFilter).toBe true
      expect(plugin.ownerFilterControlConfig.stateful).toBe true
      expect(plugin.ownerFilterControlConfig.stateId).toBe @app.getContext().getScopedStateId('iteration-planning-owner-filter')


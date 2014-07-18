Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.ui.cardboard.CardBoard'
  'Rally.ui.gridboard.plugin.GridBoardArtifactTypeChooser'
]

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
      userStoryRecord = @createUserStoryRecord
        Name: 'A User Story z'
        Iteration: null

      defectRecord = @createDefectRecord
        Name: 'A Defect'
        Iteration: null
      @ajax.whenQuerying('artifact').respondWith([userStoryRecord.data, defectRecord.data])

      @createApp()

    createUserStoryRecord: (options = {}) ->
      @mom.getRecord 'userstory', emptyCollections: true, values: Ext.apply({ DirectChildrenCount: 0, Blocked: false, Ready: false, BlockedReason: '' }, options)

    createDefectRecord: (options = {}) ->
      @mom.getRecord 'defect', emptyCollections: true, values: Ext.apply({ Requirement: null, Blocked: false, Ready: false, BlockedReason: '' }, options)
      
    getVisibleCards: (type) ->
      additionalClass = if type then ".#{type}" else ''
      cards = Ext.query ".rui-card#{additionalClass}"

      card for card in cards when Ext.fly(card).isVisible()

    filterByType: (type, expectedVisibleCards = 0) ->
      @click(css: ".#{type}-type-checkbox input").then =>
        once(
          condition: => @getVisibleCards(type).length is expectedVisibleCards
          description: "filter to be applied"
        )

    filterByBacklogCustomSearchQuery: (query) ->
      searchField = @getColumns()[0].getColumnHeader().down('rallysearchfield')
      searchStub = @stub()
      searchField.on 'search', searchStub, @, single: true

      @click(searchField.getEl().down('input')).then (el) =>
        el.sendKeys(query).then =>
          @waitForCallback searchStub

    getProgressBar: (columnIndex) ->
      @getColumns()[columnIndex].getProgressBar().down('.progress-bar')

    getProgressBarHtml: (columnIndex) ->
      @getColumns()[columnIndex].getProgressBar().getEl().select('.progress-bar-label').item(0).getHTML()

    getColumns: ->
      @app.gridboard.getGridOrBoard().getColumns()

    getTimeboxColumns: ->
      @getColumns()[1..] # exclude backlog column

    assertColumnIsFor: (iterationJson, column) ->
      expect(iterationJson._ref).toEqual column.getValue()

  beforeEach ->
    @ajax.whenQuerying('userstory').respondWith()
    @ajax.whenQuerying('defect').respondWith()
    @ajax.whenQuerying('artifact').respondWith()
    @ajax.whenQuerying('preference').respondWith({})
    @stub(Rally.ui.gridboard.plugin.GridBoardArtifactTypeChooser.prototype, '_saveArtifactTypePreference')

  afterEach ->
    @app?.destroy()

  it 'should hide only user stories when user story type checkbox is unchecked', ->
    userStoryRecord = @createUserStoryRecord Iteration: null
    defectRecord = @createDefectRecord Iteration: null
    @ajax.whenQuerying('artifact').respondWith([userStoryRecord.data, defectRecord.data])

    @createApp().then =>
      expect(@getVisibleCards('defect').length).toBe 1
      expect(@getVisibleCards('hierarchicalrequirement').length).toBe 1

      @filterByType('hierarchicalrequirement').then =>
        expect(@getVisibleCards('defect').length).toBe 1

  it 'should hide only defects when defect type checkbox is unchecked', ->
    userStoryRecord = @createUserStoryRecord Iteration: null
    defectRecord = @createDefectRecord Iteration: null
    @ajax.whenQuerying('artifact').respondWith([userStoryRecord.data, defectRecord.data])

    @createApp().then =>
      expect(@getVisibleCards('defect').length).toBe 1
      expect(@getVisibleCards('hierarchicalrequirement').length).toBe 1

      @filterByType('defect').then =>
        expect(@getVisibleCards('hierarchicalrequirement').length).toBe 1

  it 'should apply local filter', ->
    addLocalFilterStub = @stub(Rally.ui.cardboard.CardBoard.prototype, 'addLocalFilter')
    artifactsPref = ['defect']
    @stub(Rally.ui.gridboard.plugin.GridBoardArtifactTypeChooser.prototype, 'artifactsPref', artifactsPref)

    @createApp().then =>
      expect(addLocalFilterStub).toHaveBeenCalledOnce()
      expect(addLocalFilterStub.getCall(0).args[1]).toEqual artifactsPref

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

  it 'should exclude filtered artifact types when filtering by custom search query on the backlog column', ->
    @createAppWithBacklogData().then =>
      columns = @getColumns()

      @filterByBacklogCustomSearchQuery('A').then =>
        expect(columns[0].getCards().length).toBe 2
        @filterByType('hierarchicalrequirement').then =>
          expect(columns[0].getCards().length).toBe 1

  it 'should filter by artifact type and still filter by custom search query on the backlog column', ->
    @createAppWithBacklogData().then =>
      columns = @getColumns()

      @filterByType('hierarchicalrequirement').then =>
        @filterByType('defect').then =>
          @filterByBacklogCustomSearchQuery('A').then =>
            expect(columns[0].getCards().length).toBe 0

  it 'should remove all cards (including deactivated cards) when submitting a search in the backlog column', ->
    @createAppWithBacklogData().then =>
      columns = @getColumns()
      backlogColumn = columns[0]
      clearCardsSpy = @spy(backlogColumn, 'clearCards')

      @filterByType('hierarchicalrequirement').then =>
        @filterByType('defect').then =>
          @filterByBacklogCustomSearchQuery('A').then =>
            expect(clearCardsSpy).toHaveBeenCalled()
            expect(backlogColumn.getCards(true).length).toBe 2
            expect(backlogColumn.getCards().length).toBe 0

  it 'should correctly clean up deactivated cards', ->
    @createAppWithBacklogData().then =>
      columns = @getColumns()
      @filterByType('defect').then =>
        @ajax.whenQuerying('artifact').respondWith [columns[0].getCards()[0].getRecord().data]
        @filterByBacklogCustomSearchQuery('z').then =>
          @filterByType('defect').then =>
            expect(columns[0].getCards().length).toBe 1

  it 'should include filtered cards when calculating fullness of the iteration', ->
    iterationData = Helpers.TimeboxDataCreatorHelper.createTimeboxData plannedVelocity: 10

    @ajax.whenQuerying('artifact').respondWith [
        Iteration: iterationData[0]
        PlanEstimate: 2
        _ref: '/hierarchicalrequirement/1'
        _refObjectName: 'story 1'
        ObjectID: 1
      ,
        Iteration: iterationData[0]
        PlanEstimate: 2
        _ref: '/defect/2'
        _refObjectName: 'defect 1'
        ObjectID: 2
    ]

    @createApp(iterationData: iterationData).then =>
      expect(@getProgressBarHtml(1)).toBe '4 of 10'
      @filterByType('defect').then =>
        expect(@getProgressBarHtml(1)).toBe '4 of 10'
        @filterByType('hierarchicalrequirement').then =>
          expect(@getProgressBarHtml(1)).toBe '4 of 10'
          @filterByType('defect', 1).then =>
            expect(@getProgressBarHtml(1)).toBe '4 of 10'
            @filterByType('hierarchicalrequirement', 1).then =>
              expect(@getProgressBarHtml(1)).toBe '4 of 10'

  it 'should have a default card fields setting', ->
    @createApp().then =>
      expect(@app.getSetting('cardFields')).toBe 'Parent,Tasks,Defects,Discussion,PlanEstimate'

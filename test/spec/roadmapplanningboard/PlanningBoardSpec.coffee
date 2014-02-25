Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.PlanningBoard'
]

describe 'Rally.apps.roadmapplanningboard.PlanningBoard', ->

  helpers
    createCardboard: (config = {}, expectAsyncError = false, includeTypeNames = true) ->
      config = _.extend
        roadmap: @roadmapStore.first()
        timeline: @timelineStore.first()
        slideDuration: 10
        renderTo: 'testDiv'
        types: ['PortfolioItem/Feature']
      , config

      if includeTypeNames
       config.typeNames =
         child:
           name: 'Feature'

      @cardboard = Ext.create 'Rally.apps.roadmapplanningboard.PlanningBoard', config

      if(expectAsyncError)
        @once
          condition: => @errorNotifyStub.calledOnce
      else
        @waitForComponentReady(@cardboard)

    clickCollapse: ->
      collapseStub = @stub()
      @cardboard.on 'headersizechanged', collapseStub
      @click(css: '.theme-button-collapse').then =>
        @once
          condition: ->
            collapseStub.called

    clickExpand: ->
      expandStub = @stub()
      @cardboard.on 'headersizechanged', expandStub
      @click(css: '.theme-button-expand').then =>
        @once
          condition: ->
            expandStub.called

    getThemeElements: ->
      _.map(@cardboard.getEl().query('.theme_container'), Ext.get)


  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    features = Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.featureStoreData
    @errorNotifyStub = @stub Rally.ui.notify.Notifier, 'showError'
    @roadmapStore = Deft.Injector.resolve('roadmapStore')
    @timelineStore = Deft.Injector.resolve('timelineStore')
    @timeframeStore = Deft.Injector.resolve('timeframeStore')
    @planStore = Deft.Injector.resolve('planStore')
    @preliminaryEstimateStore = Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.getPreliminaryEstimateStoreFixture()
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith(features)

  afterEach ->
    @cardboard?.destroy()
    Deft.Injector.reset()


  it 'should throw an error if typeNames does not include a child property with a name', ->
    createCardboard = =>
      @createCardboard({}, false, false)

    expect(createCardboard).toThrow('typeNames must have a child property with a name')

  it 'should notify of error if the timeframe store fails to load', ->
    @stub @timeframeStore, 'load', ->
      deferred = new Deft.promise.Deferred()
      deferred.reject({storeServiceName: 'Timeline'});
      deferred.promise

    @createCardboard({}, true).then =>
      expect(@errorNotifyStub.lastCall.args[0]).toEqual
        message: 'Failed to load: Timeline service data load issue'

  it 'should notify of error if the plan store fails to load', ->
    @stub @planStore, 'load', ->
      deferred = new Deft.promise.Deferred()
      deferred.reject({storeServiceName: 'Planning'});
      deferred.promise

    @createCardboard({}, true).then =>
      expect(@errorNotifyStub.lastCall.args[0]).toEqual
        message: 'Failed to load: Planning service data load issue'

  it 'should render with a backlog column', ->
    @createCardboard().then =>
      backlogColumn = @cardboard.getBacklogColumn()

      expect(backlogColumn.getColumnHeader().getHeaderValue()).toBe "Backlog"

  it 'should have three visible planning columns', ->
    @createCardboard().then =>

      expect(@cardboard.getColumns()[1].getColumnHeader().getHeaderValue()).toBe "Q1"
      expect(@cardboard.getColumns()[2].getColumnHeader().getHeaderValue()).toBe "Q2"
      expect(@cardboard.getColumns()[3].getColumnHeader().getHeaderValue()).toBe "Future Planning Period"

  it 'should have user story count on the cards if UserStories is a selected card field', ->
    @createCardboard(cardConfig: fields: ['UserStories']).then =>
      _.each @cardboard.getColumns(), (column) =>
        _.each column.getCards(), (card) =>
          expect(card.record.data.UserStories.Count).toBe 3

  it 'should have leaf story count on the cards if UserStories is a selected card field', ->
    @createCardboard(cardConfig: fields: ['UserStories']).then =>
      _.each @cardboard.getColumns(), (column) =>
        _.each column.getCards(), (card) =>
          expect(card.record.data.LeafStoryCount).toBe 42
          expect(card.getEl().down('.rui-card-content .UserStories .user-story-count').dom.innerHTML).toBe "(42)"

  it 'should have leaf story plan estimate total on the cards if UserStories is a selected card field', ->
    @createCardboard(cardConfig: fields: ['UserStories']).then =>
      _.each @cardboard.getColumns(), (column) =>
        _.each column.getCards(), (card) =>
          expect(card.record.data.LeafStoryPlanEstimateTotal).toBe 3.14
          expect(card.getEl().down('.rui-card-content .UserStories .user-story-points').dom.innerHTML).toContain "3.14"

  it 'should have parent on the cards', ->
    @createCardboard(cardConfig: fields: ['Parent']).then =>
      _.each @cardboard.getColumns(), (column) =>
        _.each column.getCards(), (card) =>
          expect(card.getEl().down('.rui-card-content .Parent .rui-field-value').dom.innerHTML).toBe "I1: Who's Your Daddy"

  it 'should have preliminary estimate on the cards', ->
    @createCardboard(cardConfig: fields: ['PreliminaryEstimate']).then =>
      _.each @cardboard.getColumns(), (column) =>
        _.each column.getCards(), (card) =>
          expect(card.getEl().down('.rui-card-right-side .PreliminaryEstimate .rui-field-value').dom.innerHTML).toBe "L"

  it 'should have features in the appropriate columns', ->
    @createCardboard().then =>
      expect(@cardboard.getColumns()[1].getCards().length).toBe 3
      expect(@cardboard.getColumns()[2].getCards().length).toBe 2
      expect(@cardboard.getColumns()[3].getCards().length).toBe 0
      expect(@cardboard.getColumns().length).toBe(5)

  it 'should have appropriate plan capacity range', ->
    @createCardboard().then =>
      expect(@cardboard.getColumns()[1].getPlanRecord().get('lowCapacity')).toBe 2
      expect(@cardboard.getColumns()[1].getPlanRecord().get('highCapacity')).toBe 8
      expect(@cardboard.getColumns()[2].getPlanRecord().get('lowCapacity')).toBe 3
      expect(@cardboard.getColumns()[2].getPlanRecord().get('highCapacity')).toBe 30
      expect(@cardboard.getColumns()[3].getPlanRecord().get('lowCapacity')).toBe 15
      expect(@cardboard.getColumns()[3].getPlanRecord().get('highCapacity')).toBe 25

  describe 'add new column button', ->

    helpers
      clickAddNewButton: ->
        @click(css: '.scroll-button.right')


    describe 'when user is admin', ->
      beforeEach ->
        @createCardboard(isAdmin: true)

      it 'should render', ->
          expect(@cardboard.addNewColumnButton.rendered).toBeTruthy()

      describe 'when clicked', ->

        beforeEach ->
          @clickAddNewButton()

        it 'should add a new column', ->
          expect(@cardboard.getColumns().length).toBe 6

        it 'should make the new column be the last column', ->
          expect(_.last(@cardboard.getColumns()).columnHeader.down('rallyclicktoeditfieldcontainer').getValue()).toBe 'New Timeframe'

        it 'should put the field in edit mode', ->
          expect(_.last(@cardboard.getColumns()).columnHeader.down('rallyclicktoeditfieldcontainer').getEditMode()).toBeTruthy()

        it 'should update the timeframe store', ->
          expect(_.last(@timeframeStore.data.items).get('name')).toBe 'New Timeframe'

        it 'should update the plan store', ->
          expect(_.last(@planStore.data.items).get('name')).toBe 'New Plan'

    describe 'when user is not admin', ->
      beforeEach ->
        @createCardboard(isAdmin: false)

      it 'should not render', ->
        expect(@cardboard.addNewColumnButton).toBeUndefined()


  describe 'theme container interactions', ->

    it 'should show expanded themes when the board is created', ->
      @createCardboard().then =>
        _.each @getThemeElements(), (element) =>
          expect(element.isVisible()).toBe true
          expect(element.query('.field_container').length).toBe 1

    it 'should collapse themes when the theme collapse button is clicked', ->
      @createCardboard().then =>
        @clickCollapse().then =>
          _.each @getThemeElements(), (element) =>
            expect(element.isVisible()).toBe false

    it 'should expand themes when the theme expand button is clicked', ->
      @createCardboard(showTheme: false).then =>
        @clickExpand().then =>
          _.each @getThemeElements(), (element) =>
            expect(element.isVisible()).toBe true
            expect(element.query('.field_container').length).toBe 1

    it 'should return client metrics message when collapse button is clicked', ->
      @createCardboard().then =>
        @clickCollapse().then =>
          expect(@cardboard._getClickAction()).toEqual("Themes toggled from [true] to [false]")

    it 'should return client metrics message when expand button is clicked', ->
      @createCardboard(showTheme: false).then =>
        @clickExpand().then =>
          expect(@cardboard._getClickAction()).toEqual("Themes toggled from [false] to [true]")

  describe 'permissions', ->

    it 'should set editable permissions for admin', ->
      @createCardboard(isAdmin: true).then =>
        columns = _.where @cardboard.getColumns(), xtype: 'timeframeplanningcolumn'
        _.each columns, (column) =>
          expect(column.editPermissions).toEqual
            capacityRanges: true
            theme: true
            timeframeDates: true
          expect(column.dropControllerConfig.dragDropEnabled).toBe true
          expect(column.columnHeaderConfig.editable).toBe true


    it 'should set uneditable permissions for non-admin', ->
      @createCardboard(isAdmin: false).then =>
        columns = _.where @cardboard.getColumns(), xtype: 'timeframeplanningcolumn'
        _.each columns, (column) =>
          expect(column.editPermissions).toEqual
            capacityRanges: false
            theme: false
            timeframeDates: false
          expect(column.dropControllerConfig.dragDropEnabled).toBe false
          expect(column.columnHeaderConfig.editable).toBe false

  describe '#getFirstRecord', ->

    it 'should get the first record in the backlog column', ->
      @createCardboard().then =>
        expect(@cardboard.getFirstRecord().get('Name')).toBe 'Blackberry Native App'

  describe '#refresh', ->
    beforeEach ->
      @config = columnConfig:
        fields: ['UserStories']

      @createCardboard().then =>
        @parentRefreshSpy = @spy @cardboard.self.superclass, 'refresh'
        @cardboard.refresh @config

    it 'should not mutate the newConfig', ->
      # testing for object equality causes jasmine to crash when the field is not a string
      expect(typeof @config.columnConfig.fields[0]).toBe 'string'

    it 'should call refresh on the parent with extended field objects', ->
      expect(@parentRefreshSpy.lastCall.args[0].columnConfig.fields[0].name).toBe 'UserStories'

  describe 'column config', ->

    beforeEach ->
      @config =
        columnConfig:
          fields: ['FormattedID', 'Owner', 'Name', 'Project', 'PreliminaryEstimate', 'Parent', 'PercentDoneByStoryCount', 'PercentDoneByStoryPlanEstimate', 'UserStories']

      @createCardboard(@config).then =>
        @userStoriesField = _.last(@cardboard.columnConfig.fields)

    describe 'user stories field', ->

      it 'should be extended/augmented as an object in the fields array', ->
        expect(Ext.isObject(@userStoriesField)).toBe true
        expect(@userStoriesField.name).toEqual 'UserStories'

      it 'should have UserStories and LeafStoryPlanEstimateTotal as additional fetch fields', ->
        expect(@userStoriesField.fetch).toContain 'UserStories'
        expect(@userStoriesField.fetch).toContain 'LeafStoryPlanEstimateTotal'

      it 'should have a popoverConfig as an additional config', ->
        expect(@userStoriesField.popoverConfig).toBeDefined

    describe 'user stories popover config', ->

      it 'should have a bottom-first placement/positioning hierarchy', ->
        expect(@userStoriesField.popoverConfig.placement).toEqual ['bottom', 'right', 'left', 'top']

      describe 'popover columns', ->

        beforeEach ->
          @columnConfig = @userStoriesField.popoverConfig.listViewConfig.gridConfig.columnCfgs

        it 'should include ScheduleState as a column', ->
          expect(@columnConfig).toContain({ dataIndex: 'ScheduleState', text: 'State' })

        it 'should include PlanEstimate as a column', ->
          expect(@columnConfig).toContain({ dataIndex: 'PlanEstimate', editor: { decimalPrecision: 0 }})


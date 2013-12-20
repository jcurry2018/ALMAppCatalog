Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.PlanningBoard'
]

describe 'Rally.apps.roadmapplanningboard.PlanningBoard', ->

  helpers
    createCardboard: (config, expectError = false) ->
      @cardboard = Ext.create 'Rally.apps.roadmapplanningboard.PlanningBoard',
        _.extend
          roadmap: @roadmapStore.first()
          timeline: @timelineStore.first()
          slideDuration: 10
          renderTo: 'testDiv'
          types: ['PortfolioItem/Feature']
        , config

      if(expectError)
        @once
          condition: => @errorNotifyStub.calledOnce
      else
        @waitForComponentReady(@cardboard)

    clickCollapse: ->
      collapseStub = @stub()
      @cardboard.on 'headersizechanged', collapseStub
      @click(css: '.themeButtonCollapse').then =>
        @once
          condition: ->
            collapseStub.called

    clickExpand: ->
      expandStub = @stub()
      @cardboard.on 'headersizechanged', expandStub
      @click(css: '.themeButtonExpand').then =>
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
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith(features)

  afterEach ->
    @cardboard?.destroy()
    Deft.Injector.reset()

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
      backlogColumn = @cardboard.getColumns()[0]

      expect(backlogColumn.getColumnHeader().getHeaderValue()).toBe "Backlog"

  it 'should have three visible planning columns', ->
    @createCardboard().then =>

      expect(@cardboard.getColumns()[1].getColumnHeader().getHeaderValue()).toBe "Q1"
      expect(@cardboard.getColumns()[2].getColumnHeader().getHeaderValue()).toBe "Q2"
      expect(@cardboard.getColumns()[3].getColumnHeader().getHeaderValue()).toBe "Future Planning Period"

  it 'should have leaf story count on the cards', ->
      @createCardboard().then =>
        _.each @cardboard.getColumns(), (column) =>
          _.each column.getCards(), (card) =>
            expect(card.getEl().down('.rui-card-content .LeafStoryCount .rui-field-value').dom.innerHTML).toBe "42"

  it 'should have parent on the cards', ->
    @createCardboard().then =>
      _.each @cardboard.getColumns(), (column) =>
        _.each column.getCards(), (card) =>
          expect(card.getEl().down('.rui-card-content .Parent .rui-field-value').dom.innerHTML).toBe "I1: Who's Your Daddy"

  it 'should have preliminary estimate on the cards', ->
    @createCardboard().then =>
      _.each @cardboard.getColumns(), (column) =>
        _.each column.getCards(), (card) =>
          expect(card.getEl().down('.rui-card-right-side .PreliminaryEstimate .rui-field-value').dom.innerHTML).toBe "L"

  it 'should have project on the cards', ->
    @createCardboard().then =>
      _.each @cardboard.getColumns(), (column) =>
        _.each column.getCards(), (card) =>
          expect(card.getEl().down('.rui-card-content .Project .rui-field-value').dom.innerHTML).toBe "My Project"

  it 'should have percent done on the cards', ->
    @createCardboard().then =>
      _.each @cardboard.getColumns(), (column) =>
        _.each column.getCards(), (card) =>
          expect(card.getEl().down('.rui-card-content .progress-bar-container.field-PercentDoneByStoryCount .progress-bar-label')).toBeTruthy()

  it 'should have features in the appropriate columns', ->
    @createCardboard().then =>
      expect(@cardboard.getColumns()[1].getCards().length).toBe 3
      expect(@cardboard.getColumns()[2].getCards().length).toBe 2
      expect(@cardboard.getColumns()[3].getCards().length).toBe 0
      expect(@cardboard.getColumns().length).toBe(5)

  it 'should be correctly configured with stores from deft', ->
    @createCardboard().then =>
      expect(@cardboard.timeframeStore).toBeTruthy()
      expect(@cardboard.planStore).toBeTruthy()

  it 'should have appropriate plan capacity range', ->
    @createCardboard().then =>
      expect(@cardboard.getColumns()[1].getPlanRecord().get('lowCapacity')).toBe 2
      expect(@cardboard.getColumns()[1].getPlanRecord().get('highCapacity')).toBe 8
      expect(@cardboard.getColumns()[2].getPlanRecord().get('lowCapacity')).toBe 3
      expect(@cardboard.getColumns()[2].getPlanRecord().get('highCapacity')).toBe 30
      expect(@cardboard.getColumns()[3].getPlanRecord().get('lowCapacity')).toBe 15
      expect(@cardboard.getColumns()[3].getPlanRecord().get('highCapacity')).toBe 25

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
            timeframeDates: false
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
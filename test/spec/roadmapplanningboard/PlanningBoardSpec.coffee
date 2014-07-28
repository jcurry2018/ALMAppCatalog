Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.PlanningBoard'
  'Rally.env.Context'
  'Rally.data.PreferenceManager'
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
        context: Rally.environment.getContext()
        plugins: []
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

    clickAddNewButton: ->
      @click(css: '.scroll-button.right')

    getTimeframePlanningColumns: ->
      _.where @cardboard.getColumns(), xtype: 'timeframeplanningcolumn', @

    deleteLastColumn: ->
      @cardboard._deleteTimeframePlanningColumn _.last(@cardboard.getColumns())

    deleteColumn: (index) ->
      @cardboard._deleteTimeframePlanningColumn @cardboard.getColumns()[index]

    stubFeatureToggle: (toggles) ->
      stub = @stub Rally.env.Context::, 'isFeatureEnabled'
      stub.withArgs(toggle).returns(true) for toggle in toggles
      stub

    stubExpandStatePreference: (state) ->
      @stub Rally.data.PreferenceManager, 'load', ->
        deferred = new Deft.promise.Deferred()
        result = {}
        result[Rally.apps.roadmapplanningboard.PlanningBoard.PREFERENCE_NAME] = state
        deferred.resolve result
        deferred.promise


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

  it 'should have direct children count on the cards if UserStories is a selected card field', ->
    @createCardboard(cardConfig: fields: ['UserStories']).then =>
      _.each @cardboard.getColumns(), (column) =>
        _.each column.getCards(), (card) =>
          expect(card.record.data.DirectChildrenCount).toBe 39
          expect(card.getEl().down('.rui-card-content .UserStories .user-story-count').dom.innerHTML).toBe "(39)"

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
          expect(_.last(@planStore.data.items).get('name')).toBe 'New Timeframe'

    describe 'when user is not admin', ->
      beforeEach ->
        @createCardboard(isAdmin: false)

      it 'should not render', ->
        expect(@cardboard.addNewColumnButton).toBeUndefined()


  describe 'deleting columns', ->

    it 'should refresh the backlog column if the deleted column had features', ->
      @createCardboard(isAdmin: true).then =>
        refreshSpy = @spy @cardboard.getColumns()[0], 'refresh'
        @deleteColumn 1
        expect(refreshSpy).toHaveBeenCalledOnce()

    it 'should not refresh the backlog column if the deleted column did not have features', ->
      if !Ext.isGecko
        @createCardboard(isAdmin: true).then =>
          refreshSpy = @spy @cardboard.getColumns()[0], 'refresh'
          @cardboard.getColumns()[1].planRecord.set('features', []);
          @deleteColumn 1
          expect(refreshSpy).not.toHaveBeenCalledOnce()

    describe 'deleting all of the columns', ->

      beforeEach ->
        if !Ext.isGecko
          @createCardboard(isAdmin: true).then =>
            _.times @planStore.count(), => @deleteColumn(1)

      it 'should contain a single timeframe column', ->
        if !Ext.isGecko
          expect(@getTimeframePlanningColumns().length).toBe 1

      it 'should add a new empty timeframe column', ->
        if !Ext.isGecko
          expect(@cardboard.getColumns()[1].planRecord.get('features')).toEqual []

    describe 'deleting newly added columns', ->

      beforeEach ->
        if !Ext.isGecko
          @createCardboard(isAdmin: true).then =>
            @cardboard._addNewColumn().then =>
              @cardboard._addNewColumn().then =>
                @cardboard._addNewColumn().then =>
                  expect(@planStore.count()).toBe 7
                  # 0: backlog, 1-4: existing columns, 5-7: new columns
                  # delete the 'middle' new column, then the last new column, then the first
                  @deleteColumn(6).then =>
                    @deleteColumn(6).then =>
                      @deleteColumn(5)

      it 'should remove the new plans from the plan store', ->
        if !Ext.isGecko
          expect(@planStore.count()).toBe 4

      describe 'when the remaining columns are deleted', ->
          beforeEach ->
            if !Ext.isGecko
              _.times @planStore.count(), => @deleteColumn(1)

          it 'should contain a single timeframe column', ->
            if !Ext.isGecko   
              expect(@getTimeframePlanningColumns().length).toBe 1

  describe 'permissions', ->

    describe 'workspace admin', ->

      it 'should set editable permissions for admin', ->
        @createCardboard(isAdmin: true).then =>
          columns = @getTimeframePlanningColumns()
          _.each columns, (column) =>
            expect(column.editPermissions).toEqual
              capacityRanges: true
              theme: true
              timeframeDates: true
              deletePlan: true
            expect(column.dropControllerConfig.dragDropEnabled).toBe true
            expect(column.columnHeaderConfig.editable).toBe true


      it 'should set uneditable permissions for non-admin', ->
        @createCardboard(isAdmin: false).then =>
          columns = @getTimeframePlanningColumns()
          _.each columns, (column) =>
            expect(column.editPermissions).toEqual
              capacityRanges: false
              theme: false
              timeframeDates: false
              deletePlan: false
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

    describe 'without rebuildBoard option', ->

      beforeEach ->
        @cardboard.refresh()

      it 'should call the parent refresh', ->
        expect(@parentRefreshSpy).toHaveBeenCalledOnce()

    describe 'with rebuildBoard option set to true', ->

      beforeEach ->
        @firstTimeframeColumn = @cardboard.getColumns()[1]
        @showMaskSpy = @spy @cardboard, 'showMask'
        @hideMaskSpy = @spy @cardboard, 'hideMask'
        @loadColumnDataSpy = @spy @cardboard, '_loadColumnData'
        @buildColumnsSpy = @spy @cardboard, 'buildColumns'
        @refreshBacklogSpy = @spy @cardboard.getColumns()[0], 'refresh'
        @cardboard.refresh(rebuildBoard: true)

      it 'should show a mask', ->
        expect(@showMaskSpy).toHaveBeenCalledWith 'Refreshing the board...'

      it 'should hide the mask when done loading', ->
        expect(@hideMaskSpy).toHaveBeenCalled()

      it 'should load column data', ->
        expect(@loadColumnDataSpy).toHaveBeenCalledOnce()

      it 'should build columns after loading data', ->
        sinon.assert.callOrder @loadColumnDataSpy, @buildColumnsSpy

      it 'should call buildColumns with render set to true', ->
        expect(@buildColumnsSpy.lastCall.args[0].render).toBe true

      it 'should call buildColumns with firstTimeframe', ->
        expect(@buildColumnsSpy.lastCall.args[0].firstTimeframe.getId()).toBe @firstTimeframeColumn.timeframeRecord.getId()

      it 'should refresh the backlog after building columns', ->
        sinon.assert.callOrder @buildColumnsSpy, @refreshBacklogSpy

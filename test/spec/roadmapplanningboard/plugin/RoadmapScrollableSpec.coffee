Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.plugin.RoadmapScrollable'
  'Rally.apps.roadmapplanningboard.PlanningBoard'
  'Rally.apps.roadmapplanningboard.AppModelFactory'
  'Rally.data.PreferenceManager'
  'Rally.app.Context'
]

describe 'Rally.apps.roadmapplanningboard.plugin.RoadmapScrollable', ->

  helpers
    createBacklogColumn: (id) ->
      xtype: 'backlogplanningcolumn'
      testId: "#{id}"
      typeNames:
        child:
          name: 'Feature'

    createColumn: (id, date = new Date(), offset = 0) ->
      timeframeRecord = Ext.create Rally.apps.roadmapplanningboard.AppModelFactory.getTimeframeModel(),
        id: "#{id}"
        name: "#{id}"
        startDate: Ext.Date.add(date, Ext.Date.MONTH, offset-1)
        endDate: Ext.Date.add(Ext.Date.add(date, Ext.Date.MONTH, offset), Ext.Date.DAY, -1)
      planRecord = Ext.create Rally.apps.roadmapplanningboard.AppModelFactory.getPlanModel(),
        id: "#{id}"
        name: "#{id}"
        timeframe: timeframeRecord.data

      return {
        xtype: 'timeframeplanningcolumn'
        testId: "#{id}"
        timeframeRecord: timeframeRecord
        planRecord: planRecord
        typeNames:
          child:
            name: 'Feature'
        columnHeaderConfig:
          record: timeframeRecord
          fieldToDisplay: 'name'
          editable: true
        columnConfig: {}
      }

    createCardboard: (config) ->
      roadmapStore = Deft.Injector.resolve('roadmapStore')
      timelineStore = Deft.Injector.resolve('timelineStore')
      config = _.extend
        loadMask: false,
        roadmap: roadmapStore.first()
        timeline: timelineStore.first()
        timeframeColumnCount: 4
        pastColumnCount: 1
        presentColumnCount: 5
        isAdmin: true
        types: ['PortfolioItem/Feature']
        typeNames:
          child:
            name: 'Feature'
      , config

      id = 0
      date = config.date || new Date(Ext.Date.format(new Date(), 'Y-m-d'))

      columns = [
        @createBacklogColumn(id++)
      ]

      columns = columns.concat (@createColumn(num, date, num-config.pastColumnCount) for num in [id...id+(config.pastColumnCount or 0)])
      id += config.pastColumnCount
      columns = columns.concat (@createColumn(num, date, num-config.pastColumnCount) for num in [id...id+(config.presentColumnCount or 0)])

      @cardboard = Ext.create 'Rally.apps.roadmapplanningboard.PlanningBoard',
        _.extend
          buildColumns: ->
            @columns = columns

          renderTo: 'testDiv'

          plugins: [
            {ptype: 'rallytimeframescrollablecardboard', timeframeColumnCount: config.timeframeColumnCount}
          ]

          slideDuration: 10

          context: Ext.create 'Rally.app.Context'

        , config

      @plugin = @cardboard.plugins[0]

      @waitForComponentReady(@cardboard)

    scrollBackwards: ->
      @click(className: 'scroll-backwards')

    scrollForwards: ->
      @click(className: 'scroll-forwards')

    getForwardsButton: -> @cardboard.forwardsButton

    getBackwardsButton: -> @cardboard.backwardsButton

    getColumnHeaderCells: ->
      @cardboard.getEl().query('th.card-column')

    getColumnContentCells: ->
      @cardboard.getEl().query('td.card-column')

    clickAddNewButton: ->
      @click(css: '.scroll-button.rly-right')

    assertButtonIsInColumnHeader: (button, column) ->
      expect(column.getColumnHeader().getEl().getById(button.getEl().id)).not.toBeNull()

    deleteVisibleTimeframeColumn: (testId) ->
      column = @getColumnByTestId testId
      @cardboard.destroyColumn column, destroy: true

    getColumnByTestId: (testId) ->
      _.find @cardboard.getColumns(), (column) -> column.testId is testId.toString()

    isColumnVisible: (testId) ->
      !!@getColumnByTestId(testId)

    getFirstVisibleColumn: ->
      @cardboard.getColumns()[1]

    getLastVisibleColumn: ->
      _.last(@cardboard.getColumns())

    isLastVisibleColumn: (testId) ->
      @getLastVisibleColumn().testId is testId.toString()

    isFirstVisibleColumn: (testId) ->
      @getFirstVisibleColumn().testId is testId.toString()

    isPlaceholderColumn: (column) ->
      column.xtype is 'cardboardplaceholdercolumn'

    getVisiblePlaceholderColumns: ->
      _.filter @cardboard.getColumns(), (column) => @isPlaceholderColumn(column)

    getVisibleColumnIds: ->
      _.pluck @cardboard.getColumns(), 'testId'

    getIndexFromTestId: (testId) ->
      @getColumnByTestId(testId).index

    stubExpandStatePreference: (state) ->
      @stub Rally.data.PreferenceManager, 'load', ->
        deferred = new Deft.promise.Deferred()
        result = {}
        result[Rally.apps.roadmapplanningboard.PlanningBoard.PREFERENCE_NAME] = state
        deferred.resolve result
        deferred.promise

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @timeframeStore = Deft.Injector.resolve('timeframeStore')
    @planStore = Deft.Injector.resolve('planStore')
    @ajax.whenQuerying('PortfolioItem/Feature').respondWith([])

  afterEach ->
    Deft.Injector.reset()
    @cardboard?.destroy()

  describe '#destroyColumn', ->

    describe 'when forward scroll button is visible', ->

      beforeEach ->
        # starting column testIds: [ '1' ] [ '0', '2', '3', '4', '5' ] [ '6' ]
        @createCardboard()

      describe 'when first visible column is deleted', ->

        beforeEach ->
          @deleteVisibleTimeframeColumn(2)

        it 'should remove the column from the cardboard', ->
          expect(@isColumnVisible(2)).toBe false

        it 'should display the next timeframe column', ->
          expect(@isLastVisibleColumn(6)).toBe true

        it 'should not render any placeholder columns', ->
          expect(@getVisiblePlaceholderColumns().length).toBe 0

      describe 'when middle visible column is deleted', ->

        beforeEach ->
          @deleteVisibleTimeframeColumn(3)

        it 'should remove the column from the cardboard', ->
          expect(@isColumnVisible(3)).toBe false

        it 'should display the next timeframe column', ->
          expect(@isLastVisibleColumn(6)).toBe true

        it 'should not render any placeholder columns', ->
          expect(@getVisiblePlaceholderColumns().length).toBe 0

      describe 'when last visible column is deleted', ->

        beforeEach ->
          @deleteVisibleTimeframeColumn(5)

        it 'should remove the column from the cardboard', ->
          expect(@isColumnVisible(5)).toBe false

        it 'should display the next timeframe column', ->
          expect(@isLastVisibleColumn(6)).toBe true

        it 'should not render any placeholder columns', ->
          expect(@getVisiblePlaceholderColumns().length).toBe 0

    describe 'when only backwards scroll button is visible', ->

      describe 'when there are more than one visible timeframe columns', ->

        beforeEach ->
          # starting column testIds: [ '1' ] [ '0', '2', '3', '4', '5' ]
          @createCardboard(pastColumnCount: 1, presentColumnCount: 4).then =>
            @deleteVisibleTimeframeColumn(5)

        it 'should add a single placeholder column', ->
          expect(@getVisiblePlaceholderColumns().length).toBe 1

        it 'should add a placeholder column to the last position', ->
          expect(@isPlaceholderColumn(@getLastVisibleColumn())).toBe true

      describe 'when the last visible column is deleted', ->

        beforeEach ->
          # starting column testIds: [ '1' ] [ '0', '2', __ , __ , __ ]
          @createCardboard(pastColumnCount: 1, presentColumnCount: 1).then =>
            @deleteVisibleTimeframeColumn(2)

        it 'should show one column from past columns', ->
          expect(@isColumnVisible(1)).toBe true

        it 'should show the correct number of placeholder columns', ->
          expect(@getVisiblePlaceholderColumns().length).toBe 3

        it 'should not show forward scroll button', ->
          expect(@getForwardsButton().isVisible()).toBe false

    describe 'when neither of the scroll buttons are visible', ->

      beforeEach ->
        # starting column testIds: [ '0', '1', '2' , __ , __ ]
        @createCardboard(pastColumnCount: 0, presentColumnCount: 2).then =>
          @deleteVisibleTimeframeColumn(2)

      it 'should add a placeholder column', ->
        expect(@getVisiblePlaceholderColumns().length).toBe 3

  describe 'scrollable board setup', ->

    it 'should get a list of scrollable columns', ->
      @createCardboard(pastColumnCount: 0, presentColumnCount: 6).then =>
        expect(@plugin.getScrollableColumns()).toEqual @cardboard.getColumns().slice(1)

    it 'should get the last visible scrollable column', ->
      @createCardboard(pastColumnCount: 0, presentColumnCount: 6).then =>
        expect(@plugin.getLastVisibleScrollableColumn().testId).toEqual '4'

    it 'should get the first visible scrollable column', ->
      @createCardboard(pastColumnCount: 0, presentColumnCount: 6).then =>
        expect(@plugin.getFirstVisibleScrollableColumn().testId).toEqual '1'

    it 'should restrict the number of columns on the component', ->
      @createCardboard(pastColumnCount: 0, presentColumnCount: 6, timeframeColumnCount: 4).then =>
        expect(@plugin.buildColumns().length).toEqual 5 # 4 + 1 backlog

    it 'should not show past timeframes', ->
      @createCardboard(pastColumnCount: 4, presentColumnCount: 4, timeframeColumnCount: 4).then =>
        expect(@plugin.getFirstVisibleScrollableColumn().testId).toEqual '5'

    it 'should show current timeframe if the timeframe ends today', ->
      tomorrow = Ext.Date.add(new Date(), Ext.Date.DAY, 1) # This will actually move a past column to the present columns
      @createCardboard(pastColumnCount: 4, presentColumnCount: 4, date: tomorrow).then =>
        expect(@plugin.getFirstVisibleScrollableColumn().testId).toEqual '4'

    it 'should show a left scroll arrow for past timeframes', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 4, timeframeColumnCount: 4).then =>
        expect(@getBackwardsButton().hidden).toBe false

    it 'should show a right scroll arrow for extra future timeframes', ->
      @createCardboard(pastColumnCount: 0, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        expect(@getForwardsButton().hidden).toBe false

    it 'should not show a left scroll arrow if there are no past timeframes', ->
      @createCardboard(pastColumnCount: 0, presentColumnCount: 4, timeframeColumnCount: 4).then =>
        expect(@getBackwardsButton().hidden).toBe true

    it 'should not show a right scroll arrow if there are no extra future timeframes', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 4, timeframeColumnCount: 4).then =>
        expect(@getForwardsButton().hidden).toBe true

    it 'should fill in extra columns if not enough columns are provided', ->
      @createCardboard(timeframeColumnCount: 2, presentColumnCount: 1).then =>
        expect(@plugin.getScrollableColumns().length).toBe 2

    it 'should not show a forward button when not enough columns are provided', ->
      @createCardboard(timeframeColumnCount: 2, presentColumnCount: 1).then =>
        expect(@getForwardsButton().hidden).toBe true

    it 'should fill in all columns if none are provided', ->
      @createCardboard(timeframeColumnCount: 3, presentColumnCount: 0, pastColumnCount: 0).then =>
        expect(@plugin.getScrollableColumns().length).toBe 3

  describe 'add new column button', ->

    describe 'with multiple placeholder columns', ->

      beforeEach ->
        # starting column testIds: [ '1' ] [ '0', '2', '3' , __ , __ ]
        @createCardboard(pastColumnCount: 1, presentColumnCount: 2)

      it 'should render on the last column', ->
        @assertButtonIsInColumnHeader @cardboard.addNewColumnButton, _.last(@cardboard.getColumns())

    describe 'one present column', ->

      beforeEach ->
        @createCardboard(timeframeColumnCount: 3, presentColumnCount: 1, pastColumnCount: 0)

      describe 'when clicked', ->

        beforeEach ->
          @clickAddNewButton()

        it 'should replace a placeholder column with a new timeframe column', ->
          expect(Ext.ComponentQuery.query('timeframeplanningcolumn').length).toBe 2

        it 'should make the new column be the second timeframe column', ->
          expect(@cardboard.getColumns()[2].columnHeader.down('rallyclicktoeditfieldcontainer').getValue()).toBe 'New Timeframe'

        it 'should not display a forwards scroll button', ->
          expect(@getForwardsButton().isVisible()).toBe false

        it 'should not display a backwards scroll button', ->
          expect(@getBackwardsButton().isVisible()).toBe false

    describe 'with one past column and no present columns', ->

      beforeEach ->
        @createCardboard(timeframeColumnCount: 3, presentColumnCount: 0, pastColumnCount: 1)

      it 'should be rendered in the last column', ->
        @assertButtonIsInColumnHeader @cardboard.addNewColumnButton, @plugin.getLastVisibleScrollableColumn()

      it 'should show the first past column', ->
        expect(Ext.ComponentQuery.query('timeframeplanningcolumn').length).toBe 1

      describe 'when clicked', ->

        beforeEach ->
          @clickAddNewButton()

        it 'should add a new column', ->
          expect(Ext.ComponentQuery.query('timeframeplanningcolumn').length).toBe 2

        it 'should make the new column be the second column', ->
          expect(@cardboard.getColumns()[2].columnHeader.down('rallyclicktoeditfieldcontainer').getValue()).toBe 'New Timeframe'

        it 'should put the field in edit mode', ->
          expect(@cardboard.getColumns()[2].columnHeader.down('rallyclicktoeditfieldcontainer').getEditMode()).toBeTruthy()

        it 'should update the timeframe store', ->
          expect(_.last(@timeframeStore.data.items).get('name')).toBe 'New Timeframe'

        it 'should update the plan store', ->
          expect(_.last(@planStore.data.items).get('name')).toBe 'New Timeframe'

        it 'should not display a forwards scroll button', ->
          expect(@getForwardsButton().isVisible()).toBe false

        it 'should not display a backwards scroll button', ->
          expect(@getBackwardsButton().isVisible()).toBe false

    describe 'with present and future columns', ->

      beforeEach ->
        @createCardboard(timeframeColumnCount: 3, presentColumnCount: 4, pastColumnCount: 0)

      it 'should be undefined', ->
        expect(@cardboard.addNewColumnButton).toBeUndefined()

      describe 'when forward scroll button is clicked', ->

        beforeEach ->
          @scrollForwards()

        it 'should render', ->
          expect(@cardboard.addNewColumnButton.rendered).toBeTruthy()

        describe 'when clicked', ->

          beforeEach ->
            @clickAddNewButton()

          it 'should add a new column', ->
            expect(@plugin.scrollableColumns.length).toBe 5

          it 'should make the new column be the last column', ->
            expect(_.last(@cardboard.getColumns()).columnHeader.down('rallyclicktoeditfieldcontainer').getValue()).toBe 'New Timeframe'

          it 'should put the field in edit mode', ->
            expect(_.last(@cardboard.getColumns()).columnHeader.down('rallyclicktoeditfieldcontainer').getEditMode()).toBeTruthy()

          it 'should update the timeframe store', ->
            expect(_.last(@timeframeStore.data.items).get('name')).toBe 'New Timeframe'

          it 'should update the plan store', ->
            expect(_.last(@planStore.data.items).get('name')).toBe 'New Timeframe'

  describe 'when back scroll button is clicked', ->

    describe 'when more than one placeholder column is visible', ->

      beforeEach ->
        @createCardboard(pastColumnCount: 2, presentColumnCount: 2).then =>

      it 'should remove a placeholder column', ->
        @scrollBackwards().then =>
          expect(@getVisiblePlaceholderColumns().length).toBe 1

      it 'should remove all placeholder columns when scrolled backwards twice', ->
        @scrollBackwards().then =>
          @scrollBackwards().then =>
            expect(@getVisiblePlaceholderColumns().length).toBe 0

    it 'should scroll backward', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 4, timeframeColumnCount: 4).then =>
        @scrollBackwards().then =>
          expect(@plugin.getFirstVisibleScrollableColumn().timeframeRecord.getId()).toEqual '1'
          expect(@getBackwardsButton().hidden).toBe true

    it 'should contain the same number of columns', ->
      @createCardboard(pastColumnCount: 4, presentColumnCount: 4, timeframeColumnCount: 4).then =>
        @scrollBackwards().then =>
          expect(@plugin.getScrollableColumns().length).toEqual 4

    it 'should show 1 header cell for each column', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @scrollBackwards().then =>
          expect(@getColumnHeaderCells().length).toBe 5 # 4 + 1 backlog

    it 'should show 1 content cell for each column', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @scrollBackwards().then =>
          expect(@getColumnContentCells().length).toBe 5 # 4 + 1 backlog

    it 'should render newly visible column in left-most column', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @scrollBackwards().then =>
          expect(@plugin.getFirstVisibleScrollableColumn().getColumnHeaderCell().dom).toBe @getColumnHeaderCells()[1]
          expect(@plugin.getFirstVisibleScrollableColumn().getContentCellContainers()[0].dom).toBe @getColumnContentCells()[1]

    it 'should re-render scroll buttons', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @scrollBackwards().then =>
          @assertButtonIsInColumnHeader @getForwardsButton(), @plugin.getLastVisibleScrollableColumn()
          @assertButtonIsInColumnHeader @getBackwardsButton(), @plugin.getFirstVisibleScrollableColumn()

    it 'should destroy old scroll buttons', ->
      @createCardboard(pastColumnCount: 2, presentColumnCount: 6, timeframeColumnCount: 4).then =>
        @scrollBackwards().then =>
          expect(@cardboard.getEl().query('.scroll-button').length).toBe 2

    it 'should add temp filters to newly added column when board is filtered', ->
      nameFilter = new Rally.data.QueryFilter
        property: 'Name',
        operator: '=',
        value: 'Android Support'

      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @cardboard.filter nameFilter
        @scrollBackwards().then =>
          expect(@plugin.getLastVisibleScrollableColumn().filterCollection.tempFilters.undefined.toString()).toBe nameFilter.toString()

    it 'should handle only 1 column', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 1, timeframeColumnCount: 1).then =>
        @scrollBackwards().then =>
          expect(@plugin.getFirstVisibleScrollableColumn().timeframeRecord.getId()).toEqual '1'

    it 'should scroll with placeholder columns', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 1, timeframeColumnCount: 4).then =>
        @scrollBackwards().then =>
          expect(@getColumnContentCells().length).toBe 5 # 2 + 1 backlog

  describe 'when forward scroll button is clicked', ->

    it 'should scroll forward', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @scrollForwards().then =>
          expect(@plugin.getFirstVisibleScrollableColumn().timeframeRecord.getId()).toEqual '3'
          expect(@getForwardsButton().hidden).toBe true

    it 'should contain the same number of columns', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @scrollForwards().then =>
          expect(@plugin.getScrollableColumns().length).toEqual 4

    it 'should show 1 header cell for each column', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @scrollForwards().then =>
          expect(@getColumnHeaderCells().length).toBe 5 # 4 + 1 backlog

    it 'should show 1 content cell for each column', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @scrollForwards().then =>
          expect(@getColumnContentCells().length).toBe 5 # 4 + 1 backlog

    it 'should render newly visible column in right-most column', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @scrollForwards().then =>
          expect(@plugin.getLastVisibleScrollableColumn().getColumnHeaderCell().dom).toBe (_.last @getColumnHeaderCells())
          expect(@plugin.getLastVisibleScrollableColumn().getContentCellContainers()[0].dom).toBe (_.last @getColumnContentCells())

    it 'should re-render scroll buttons', ->
      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @scrollForwards().then =>
          @assertButtonIsInColumnHeader @getForwardsButton(), @plugin.getLastVisibleScrollableColumn()
          @assertButtonIsInColumnHeader @getBackwardsButton(), @plugin.getFirstVisibleScrollableColumn()

    it 'should destroy old scroll buttons', ->
      @createCardboard(pastColumnCount: 2, presentColumnCount: 6, timeframeColumnCount: 4).then =>
        @scrollForwards().then =>
          expect(@cardboard.getEl().query('.scroll-button').length).toBe 2

    it 'should add temp filters to newly added column when board is filtered', ->
      nameFilter = new Rally.data.QueryFilter
        property: 'Name',
        operator: '=',
        value: 'Android Support'

      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @cardboard.filter nameFilter
        @scrollForwards().then =>
          expect(@plugin.getLastVisibleScrollableColumn().filterCollection.tempFilters.undefined.toString()).toBe nameFilter.toString()

    it 'should handle only 1 column', ->
      @createCardboard(pastColumnCount: 0, presentColumnCount: 2, timeframeColumnCount: 1).then =>
        @scrollForwards().then =>
          expect(@plugin.getFirstVisibleScrollableColumn().timeframeRecord.getId()).toEqual '2'

  describe '#_onColumnDateRangeChange', ->

    it 'should move the updated column to fill the gap', ->
      # starting column testIds: [ '0', '1', '2', '3', '4' ] [ '5' ]
      @createCardboard(presentColumnCount: 5, pastColumnCount: 0).then =>
        deletedColumnTimeframe = @getColumnByTestId(2).timeframeRecord

        # updated column testIds: [ '0', '1', '3', '4', '5' ]
        @deleteVisibleTimeframeColumn(2)

        @updatedColumn = @getColumnByTestId(5)
        @updatedColumn.timeframeRecord.set('startDate', deletedColumnTimeframe.get('startDate'))
        @updatedColumn.timeframeRecord.set('endDate', deletedColumnTimeframe.get('endDate'))

        @cardboard._onColumnDateRangeChange(@updatedColumn)

        expect(@getVisibleColumnIds()).toEqual [ '0', '1', '5', '3', '4' ]

    it 'should shift the board to show the updated column in the first position', ->
      # starting column testIds: [ '0', '1', '2', '3', '4' ] [ '5', '6', '7' ]
      @createCardboard(presentColumnCount: 7, pastColumnCount: 0).then =>
        deletedColumnTimeframe = @getColumnByTestId(2).timeframeRecord

        # updated column testIds: [ '0', '1', '3', '4', '5' ] [ '6', '7' ]
        @deleteVisibleTimeframeColumn(2)

        @scrollForwards().then =>
          @scrollForwards().then =>
            # after scrolling: [ '0', '4', '5', '6', '7' ]

            @updatedColumn = @getColumnByTestId(7)
            @updatedColumn.timeframeRecord.set('startDate', deletedColumnTimeframe.get('startDate'))
            @updatedColumn.timeframeRecord.set('endDate', deletedColumnTimeframe.get('endDate'))

            @cardboard._onColumnDateRangeChange(@updatedColumn)

            expect(@getVisibleColumnIds()).toEqual [ '0', '7', '3', '4', '5' ]

  describe '#_getIndexOfFirstColumnToShow', ->

    describe 'when passing it a timeframe', ->

      beforeEach ->
        @createCardboard(presentColumnCount: 7, pastColumnCount: 0)

      it 'should return the index of the column matching the timeframe if one exists', ->
        # starting column testIds: [ '0', '1', '2', '3', '4' ] [ '5', '6', '7' ]
        index = @plugin._getIndexOfFirstColumnToShow(getId: -> '2')
        # expected column testIds: [ '1' ] [ '0', '2', '3', '4', '5' ] [ '6', '7' ]
        expect(index).toBe @getIndexFromTestId(2)

    describe 'when not passing a timeframe', ->

      it 'should return the index of the first present column if one exists', ->
        # starting column testIds: [ '1', '2', '3' ] [ '0', '4', '5', '6', '7' ]
        @createCardboard(presentColumnCount: 4, pastColumnCount: 3).then =>
          index = @plugin._getIndexOfFirstColumnToShow()
          expect(index).toBe @getIndexFromTestId(4)

      it 'should return the index of the most recent past column if one exists', ->
        # starting column testIds: [ '1', '2', '3' ] [ '0' ]
        @createCardboard(presentColumnCount: 0, pastColumnCount: 3).then =>
          index = @plugin._getIndexOfFirstColumnToShow()
          # expected column testIds: [ '1', '2' ] [ '0', '3', __ , __ , __ ]
          expect(index).toBe @getIndexFromTestId(3)

  describe '#buildColumns', ->

    beforeEach ->
      @createCardboard(presentColumnCount: 7, pastColumnCount: 0).then =>
        @hideColumnsSpy = @spy @plugin, '_hideColumns'
        @syncColumnsSpy = @spy @plugin, '_syncColumns'

    describe 'render set to true', ->

      beforeEach ->
        @cardboard.buildColumns(render: true)

      it 'should hide existing visible columns', ->
        expect(@hideColumnsSpy).toHaveBeenCalled()

      it 'should call syncColumns', ->
        expect(@syncColumnsSpy).toHaveBeenCalled()

    describe 'render is not set', ->

      beforeEach ->
        @cardboard.buildColumns()

      it 'should not hide existing visible columns', ->
        expect(@hideColumnsSpy).not.toHaveBeenCalled()

      it 'should not call syncColumns', ->
        expect(@syncColumnsSpy).not.toHaveBeenCalled()


  describe '#filter', ->
    it 'should save the filter to the temp filter collection', ->
      nameFilter = new Rally.data.QueryFilter
        property: 'Name',
        operator: '=',
        value: 'Android Support'

      @createCardboard(pastColumnCount: 1, presentColumnCount: 5, timeframeColumnCount: 4).then =>
        @cardboard.filter nameFilter
        expect(@cardboard.filterCollection.tempFilters.undefined.toString()).toBe nameFilter.toString()


Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.PlanningBoardColumn'
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
]

describe 'Rally.apps.roadmapplanningboard.PlanningBoardColumn', ->
  helpers
    createColumn: ->
      target = 'testDiv'

      config = Ext.merge {},
        store: Deft.Injector.resolve('featureStore')
        context:
          getScopedStateId: (stateId) -> return stateId
        listeners:
          ready: ->
            Rally.BrowserTest.publishComponentReady @
        renderTo: target
        contentCell: target
        headerCell: target, @columnConfig

      @column = Ext.create 'Rally.apps.roadmapplanningboard.PlanningBoardColumn', config
      @waitForComponentReady @column

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @columnConfig = {}
    @nameFilter = new Rally.data.QueryFilter
      property: 'Name',
      operator: '=',
      value: 'Android Support'

  afterEach ->
    Deft.Injector.reset()
    @column?.destroy()

  it 'should have a column existing', ->
    @createColumn().then =>
      expect(@column).toBeTruthy()

  it 'should filter by matching record criteria function', ->
    @createColumn().then =>
      @column.isMatchingRecord = ->
        true

      expect(@column.getCards().length).toBe 10

      @column.isMatchingRecord = (record) ->
        record.get('ObjectID') == 1000
      @column.refresh()

      expect(@column.getCards().length).toBe 1

  it 'should have the planning-column css class on header and content', ->
    @createColumn().then =>
      expect(@column.getContentCell().hasCls 'planning-column').toBeTruthy()
      expect(@column.getColumnHeaderCell().hasCls 'planning-column').toBeTruthy()

  describe 'base filter', ->
    it 'should handle single object base filter', ->
      @columnConfig.baseFilter =
        property: 'Property1',
        operator: '=',
        value: 'Value1'
      baseFilter = new Rally.data.QueryFilter(@columnConfig.baseFilter)

      @createColumn().then =>
        expect(@column.getStoreFilter().toString()).toEqual baseFilter.toString()

    it 'should handle object array base filter', ->
      filter1 =
        property: 'Property1',
        operator: '=',
        value: 'Value1'
      filter2 =
        property: 'Property2',
        operator: '=',
        value: 'Value2'
      @columnConfig.baseFilter = [filter1, filter2]
      baseFilter = new Rally.data.QueryFilter(filter1).and(new Rally.data.QueryFilter(filter2))

      @createColumn().then =>
        expect(@column.getStoreFilter().toString()).toEqual baseFilter.toString()

    it 'should handle empty array base filter', ->
      @columnConfig.baseFilter = []
      @createColumn().then =>
        expect(@column.baseFilter).toBeUndefined()
        expect(@column.getStoreFilter()).toBeUndefined()

    it 'should handle query filter base filter', ->
      @columnConfig.baseFilter = @nameFilter.and new Rally.data.QueryFilter(
        property: 'Property1',
        operator: '=',
        value: 'Value1')

      @createColumn().then =>
        expect(@column.getStoreFilter()).toEqual @columnConfig.baseFilter


  describe 'non-filterable column', ->
    it 'filterable defaults to false', ->
      @createColumn().then =>
        expect(@column.filterable).toBe false

    it 'does not render filterable control', ->
      @createColumn().then =>
        expect(!!@column.filterButton).toBe false

    it 'appiles baseFilter to data load', ->
      @columnConfig.baseFilter = @nameFilter

      @createColumn().then =>
        expect(@column.getStoreFilter()).toEqual @nameFilter

  describe 'filterable column', ->
    beforeEach ->
      @columnConfig =
        filterable: true
        baseFilter:
          property: 'ActualEndDate',
          operator: '=',
          value: 'null'
        getColumnIdentifier: => "gotmeanid"

    it 'should throw error if getColumnIdentifier is not overridden', ->
      delete @columnConfig.getColumnIdentifier
      createColumn = => @createColumn()
      expect(createColumn).toThrow 'Need to override this to ensure unique identifier for persistence'

    it 'should render filterable control', ->
      @createColumn().then =>
        expect(!!@column.filterButton).toBe true

    it 'should apply queryFilter on top of baseFilter', ->
      @columnConfig.baseFilter = []
      @createColumn().then =>
        @column.queryFilter = @nameFilter
        expect(@column.getStoreFilter().toString()).toBe '(Name = "Android Support")'

    it 'should apply queryFilter on top of baseFilter', ->
      @createColumn().then =>
        @column.queryFilter = @nameFilter
        expect(@column.getStoreFilter().toString()).toBe '((ActualEndDate = "null") AND (Name = "Android Support"))'

    it 'should apply queryFilter at Done on popover', ->
      @createColumn().then =>
        @click(@column.filterButton.getEl()).then =>
          popover = @column.filterButton.getController().popover
          popover.down('#customqueryfilter').setValue(@nameFilter.toString())
          @click(popover.down('#filterDone').getEl()).then =>
            expect(@column.getStoreFilter().toString()).toBe '((ActualEndDate = "null") AND (Name = "Android Support"))'

    it 'should apply queryFilter at initial load', ->
      @stub Rally.ui.filter.view.FilterButton::, 'getFilter', -> [
        property: 'Name',
        operator: '=',
        value: 'Some name'
      ]

      @createColumn().then =>
        expect(@column.getStoreFilter().toString()).toBe '((ActualEndDate = "null") AND (Name = "Some name"))'

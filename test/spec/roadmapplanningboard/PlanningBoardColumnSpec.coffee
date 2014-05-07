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
        cardConfig:
          preliminaryEstimateStore: Deft.Injector.resolve('preliminaryEstimateStore')
        context:
          getScopedStateId: (stateId) -> stateId
          getWorkspace: () ->
            _refObjectUUID: '84f98b22-69a3-441b-a70a-96679aeccc20'
        listeners:
          ready: ->
            Rally.BrowserTest.publishComponentReady @
        renderTo: target
        contentCell: target
        headerCell: target, @columnConfig
        filterCollection: Ext.create 'Rally.data.filter.FilterCollection'

      @column = Ext.create 'Rally.apps.roadmapplanningboard.PlanningBoardColumn', config
      @waitForComponentReady @column

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @columnConfig =
      typeNames:
        child:
          name: 'Feature'
    @nameFilter = new Rally.data.QueryFilter
      property: 'Name',
      operator: '=',
      value: 'Android Support'
    @parentFilter = new Rally.data.QueryFilter
      property: 'Parent'
      operator: '='
      value: 'SomeInitiative'

  afterEach ->
    Deft.Injector.reset()
    @column?.destroy()

  it 'should throw an error if typeNames does not include a child property with a name', ->
    delete @columnConfig.typeNames

    createColumn = =>
      @createColumn()

    expect(createColumn).toThrow('typeNames must have a child property with a name')

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
      @columnConfig = Ext.merge {}, @columnConfig,
        filterable: true
        baseFilter:
          property: 'ActualEndDate',
          operator: '=',
          value: 'null'
        getColumnIdentifier: =>
          "gotmeanid"

    it 'should render filterable control', ->
      @createColumn().then =>
        expect(!!@column.filterButton).toBe true

    it 'should append workspace uuid to the preference name structure', ->
      @createColumn().then =>
        expect(@column.filterButton.stateId).toBe 'filter.gotmeanid.84f98b22-69a3-441b-a70a-96679aeccc20'

    it 'should throw error if getColumnIdentifier is not overridden', ->
      delete @columnConfig.getColumnIdentifier
      createColumn = =>
        @createColumn()
      expect(createColumn).toThrow 'Need to override this to ensure unique identifier for persistence'

    it 'should add a parent filter if typeNames includes a parent', ->
      @columnConfig.typeNames.parent =
        name: 'Initiative'
        typePath: 'PortfolioItems/Initiative'
      @createColumn().then =>
        parentFilter = _.find(@column.filterButton.items, (item) -> item.xtype is 'rallyparentfilter')
        expect(!!parentFilter).toBe true

    it 'should not add a parent filter if typeNames does not include a parent', ->
      @createColumn().then =>
        parentFilter = _.find(@column.filterButton.items, (item) -> item.xtype is 'rallyparentfilter')
        expect(!!parentFilter).toBe false

    it 'should add a custom query filter control', ->
      @createColumn().then =>
        queryFilter = _.find(@column.filterButton.items, (item) -> item.xtype is 'rallycustomqueryfilter')
        expect(!!queryFilter).toBe true

    it 'should apply custom query filters on top of empty baseFilter', ->
      @columnConfig.baseFilter = []
      @createColumn().then =>
        @column.filters = [@nameFilter]
        expect(@column.getStoreFilter().toString()).toBe '(Name = "Android Support")'

    it 'should apply custom query filters on top of baseFilter', ->
      @createColumn().then =>
        @column.filters = [@nameFilter]
        expect(@column.getStoreFilter().toString()).toBe '((ActualEndDate = "null") AND (Name = "Android Support"))'

    it 'should handle multiple custom filters on top of baseFilter', ->
      @createColumn().then =>
        @column.filters = [@parentFilter, @nameFilter]
        expect(@column.getStoreFilter().toString()).toBe '(((ActualEndDate = "null") AND (Parent = "SomeInitiative")) AND (Name = "Android Support"))'

    it 'should apply custom filters when Done is clicked on popover', ->
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

  describe '#refreshRecords', ->

    it 'should get latest store filters', ->
      @createColumn().then =>
        getStoreFilterSpy = @spy @column, 'getStoreFilter'
        @stub @column.store, 'reloadRecord', =>
          deferred = new Deft.Deferred()
          deferred.resolve @mom.getRecord('userstory')
          deferred.promise

        @column.refreshRecord(@column.getRecords()[0], ->).then =>
          expect(getStoreFilterSpy).toHaveBeenCalledOnce()

  describe '#refresh', ->

    it 'should clear filters', ->

      @createColumn().then =>
        clearSpy = @spy @column.filterCollection, 'clearAllFilters'
        @column.refresh()
        expect(clearSpy).toHaveBeenCalled()

  describe '#getAllFetchFields', ->

    beforeEach ->
      @columnConfig.fields = ['PreliminaryEstimate','UserStories']
      @columnConfig.cardConfig =
        fieldMappings:
          PreliminaryEstimate: [
            { name: 'PreliminaryEstimate', properties: ['Value', 'Name'] }
          ]

    describe 'with shallowFetch enabled', ->

      beforeEach ->
        @columnConfig.storeConfig = useShallowFetch: true
        @createColumn()

      it 'should add additional fetch fields for fields with custom config', ->
        expect(@column.getAllFetchFields()).toContain('PreliminaryEstimate[Value;Name]');

    describe 'with shallowFetch disabled', ->

      beforeEach ->
        @columnConfig.storeConfig = useShallowFetch: false
        @createColumn()

      it 'should add additional fetch fields for fields with custom config', ->
        expect(@column.getAllFetchFields()).toContain('PreliminaryEstimate');
        expect(@column.getAllFetchFields()).toContain('Value');
        expect(@column.getAllFetchFields()).toContain('Name');

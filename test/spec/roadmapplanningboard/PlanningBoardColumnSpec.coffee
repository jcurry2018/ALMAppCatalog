Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.PlanningBoardColumn'
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
]

describe 'Rally.apps.roadmapplanningboard.PlanningBoardColumn', ->
  helpers
    createColumn: ->
      target = 'testDiv'

      @column = Ext.create 'Rally.apps.roadmapplanningboard.PlanningBoardColumn', Ext.merge {},
        store: Deft.Injector.resolve('featureStore')
        cardConfig:
          preliminaryEstimateStore: Deft.Injector.resolve('preliminaryEstimateStore')
        context:
          getProject: -> Rally.environment.getContext().getProject()
          getScopedStateId: (stateId) -> stateId
          getWorkspace: -> _refObjectUUID: '84f98b22-69a3-441b-a70a-96679aeccc20'
        listeners:
          ready: ->
            Rally.BrowserTest.publishComponentReady @
        renderTo: target
        contentCell: target
        headerCell: target, @columnConfig
        filterCollection: Ext.create 'Rally.data.filter.FilterCollection'
      @waitForComponentReady @column

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @columnConfig =
      typeNames:
        child:
          name: 'Feature'

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
      @column.refresh store: @column.store

      expect(@column.getCards().length).toBe 1

  it 'should have the planning-column css class on header and content', ->
    @createColumn().then =>
      expect(@column.getContentCell().hasCls 'planning-column').toBeTruthy()
      expect(@column.getColumnHeaderCell().hasCls 'planning-column').toBeTruthy()

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

  describe '#getAllFetchFields', ->

    beforeEach ->
      @columnConfig.fields = ['PreliminaryEstimate','UserStories']

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

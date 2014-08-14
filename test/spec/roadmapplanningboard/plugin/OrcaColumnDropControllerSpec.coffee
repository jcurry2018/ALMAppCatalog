Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.TimeframePlanningColumn'
  'Rally.apps.roadmapplanningboard.BacklogBoardColumn'
  'Rally.apps.roadmapplanningboard.plugin.OrcaColumnDropController'
  'Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory'
  'Rally.data.Ranker'
]

describe 'Rally.apps.roadmapplanningboard.plugin.OrcaColumnDropController', ->
  helpers
    dragCard: (options) ->
      dragData =
        card: options.sourceColumn.getCards()[options.sourceIndex]
        column: options.sourceColumn
        backlogColumn: options.backlogColumn
        row: @row
      sourcePlanRecord = options.sourceColumn.planRecord
      destPlanRecord = options.destColumnDropController.cmp.planRecord

      @recordSaveStub?.restore()
      @sourcePlanRecordSaveStub?.restore()
      @destPlanRecordSaveStub?.restore()

      @recordSaveStub = @stub dragData.card.getRecord(), 'save', () ->

      if sourcePlanRecord
        @sourcePlanRecordSaveStub = @stub sourcePlanRecord, 'save', (options) ->
          expect(@dirty).toBeTruthy()

      if destPlanRecord and destPlanRecord isnt sourcePlanRecord
        @destPlanRecordSaveStub = @stub destPlanRecord, 'save', () ->
          expect(@dirty).toBeTruthy()

      options.destColumnDropController.onCardDropped
        row: @row
        column: options.destColumnDropController.cmp
      ,
        dragData
      ,
       options.destIndex

    _createColumn: (type, options) ->
      loadStub = @stub()
      Ext.merge options,
        columnClass: type
        listeners:
          load: loadStub
      column = @cardboardHelper.createColumn(options)
      @waitForCallback(loadStub).then =>
        column

    _createPlanningColumn: (options, shouldRender = true) ->
      target = 'testDiv' if shouldRender
      options =
        store: Ext.create 'Ext.data.Store',
          extend: 'Ext.data.Store'
          model: Rally.test.mock.data.WsapiModelFactory.getModel 'PortfolioItem/Feature'
          proxy:
            type: 'memory'
          data: options.data

        planRecord: options.plan
        lowestPIType: 'PortfolioItem/Feature'
        timeframeRecord: options.timeframe
        enableCrossColumnRanking: true
        ownerCardboard: {}
        renderTo: target
        contentCell: target
        headerCell: target
        renderCardsWhenReady: false
        typeNames:
          child:
            name: 'Feature'

      @_createColumn 'Rally.apps.roadmapplanningboard.TimeframePlanningColumn', options

    expectPlanFeaturesToMatchCards: (column) ->
      features = column.planRecord.get('features')
      cardRecords = _.map column.getCards(), (card) -> card.getRecord()

      expect(features.length).toBe cardRecords.length
      for i in [0...features.length]
        expect(features[i].id).toBe cardRecords[i].get('_refObjectUUID')

  beforeEach ->
    @cardboardHelper = Rally.test.helpers.CardBoard
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()

    planStore = Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.getPlanStoreFixture()
    timeframeStore = Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.getTimeframeStoreFixture()
    secondFeatureStore = Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.getSecondFeatureStoreFixture()

    newSorter = property: Rally.data.Ranker.RANK_FIELDS.MANUAL
    secondFeatureStore.sort [newSorter]

    plan = planStore.getById('513617ecef8623df1391fefc')
    features = Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.featureStoreData
    columns = []

    @leftColumnOptions =
      plan: plan
      timeframe: timeframeStore.getById(plan.get('timeframe').id)
      data: Rally.test.mock.ModelObjectMother.getRecords 'PortfolioItemFeature',
        values: features.slice(0,3)

    columns.push @_createPlanningColumn(@leftColumnOptions).then (@leftColumn) =>

    plan = planStore.getById('513617f7ef8623df1391fefd')
    @rightColumnOptions =
      plan: plan
      timeframe: timeframeStore.getById(plan.get('timeframe').id)
      data: Rally.test.mock.ModelObjectMother.getRecords 'PortfolioItemFeature',
        values: features.slice(5,7)

    columns.push @_createPlanningColumn(@rightColumnOptions).then (@rightColumn) =>

    columns.push @_createColumn('Rally.apps.roadmapplanningboard.BacklogBoardColumn',
      store: secondFeatureStore
      planStore: planStore
      lowestPIType: 'PortfolioItem/Feature'
      enableCrossColumnRanking: true
      ownerCardboard: {}
      renderCardsWhenReady: false
      typeNames:
        child:
          name: 'Feature'
    ).then (@backlogColumn) =>

    rowContentCell = Ext.get('testDiv').createChild()
    @row =
      getContentCellFor: -> rowContentCell
      getRowValue: ->
      fieldDef:
        name: 'long fingernails' 

    @ajaxRequest = @stub Ext.Ajax, 'request', (options) ->
      options.success.call(options.scope)

    Deft.Promise.all(columns).then =>
      @leftColumnDropController = Ext.create 'Rally.apps.roadmapplanningboard.plugin.OrcaColumnDropController'
      @leftColumnDropController.init(@leftColumn)
      @rightColumnDropController = Ext.create 'Rally.apps.roadmapplanningboard.plugin.OrcaColumnDropController'
      @rightColumnDropController.init(@rightColumn)
      @backlogColumnDropController = Ext.create 'Rally.apps.roadmapplanningboard.plugin.OrcaColumnDropController'
      @backlogColumnDropController.init(@backlogColumn)

  afterEach ->
    Deft.Injector.reset()
    @leftColumnDropController?.destroy()
    @rightColumnDropController?.destroy()
    @backlogColumnDropController?.destroy()
    @leftColumn?.destroy()
    @rightColumn?.destroy()
    @backlogColumn?.destroy()

  describe 'when drag and drop is disabled', ->
    it 'should not have a drop target', ->
      @_createPlanningColumn(@leftColumnOptions, true).then (column) =>
        controller = Ext.create 'Rally.apps.roadmapplanningboard.plugin.OrcaColumnDropController',
          dragDropEnabled: false
        controller.init(column)
        column.fireEvent('rowadd', this, @row)

        expect(controller.dropTarget).toBeUndefined()

  describe 'when drag and drop is enabled', ->
    it 'should have a drop target', ->
      @_createPlanningColumn(@rightColumnOptions, true).then (column) =>
        controller = Ext.create 'Rally.apps.roadmapplanningboard.plugin.OrcaColumnDropController',
          dragDropEnabled: true
        controller.init(column)
        column.fireEvent('rowadd', this, @row)
        expect(controller.dropTargets).toBeDefined()

  describe 'when drag and drop ranking', ->
    describe 'within a backlog', ->
      it 'should send rankAbove when card is dragged to top of the column', ->
        @dragCard
          sourceColumn: @backlogColumn
          destColumnDropController: @backlogColumnDropController
          sourceIndex: 1
          destIndex: 0
        expect(@recordSaveStub.lastCall.args[0].params.rankAbove).toContain '1010'

      it 'should send rankBelow when card is dragged lower than top of the column', ->
        @dragCard
          sourceColumn: @backlogColumn
          destColumnDropController: @backlogColumnDropController
          sourceIndex: 0
          destIndex: 2

        expect(@recordSaveStub.lastCall.args[0].params.rankBelow).toContain '1011'

    describe 'from backlog to plan', ->

      describe 'from top to top', ->

        beforeEach ->
          @backlogCardCount = @backlogColumn.getCards().length
          @leftCardCount = @leftColumn.getCards().length
          @card = @backlogColumn.getCards()[0]

          @dragCard
            sourceColumn: @backlogColumn
            destColumnDropController: @leftColumnDropController
            sourceIndex: 0
            destIndex: 0

        it 'should have correct card count in backlog column', ->
          expect(@backlogColumn.getCards().length).toBe @backlogCardCount - 1

        it 'should remove the card from the backlog column', ->
          expect(_.pluck(@backlogColumn.getCards(), 'id')).toNotContain(@card.getId())

        it 'should have correct card count in left column', ->
          expect(@leftColumn.getCards().length).toBe @leftCardCount + 1

        it 'should place the card in the correct location', ->
          expect(@leftColumn.getCards()[0].getId()).toEqual @card.getId()

        it 'should call the save method of the left column', ->
          expect(@destPlanRecordSaveStub).toHaveBeenCalledOnce()

        it 'should send rankAbove', ->
          expect(@destPlanRecordSaveStub.lastCall.args[0].params.rankAbove).toContain '1000'

        it 'should update plan record', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)

      describe 'from top to bottom', ->

        beforeEach ->
          @backlogCardCount = @backlogColumn.getCards().length
          @leftCardCount = @leftColumn.getCards().length
          @card = @backlogColumn.getCards()[0]

          @dragCard
            sourceColumn: @backlogColumn
            destColumnDropController: @leftColumnDropController
            sourceIndex: 0
            destIndex: 3

        it 'should have correct card count in backlog column', ->
          expect(@backlogColumn.getCards().length).toBe @backlogCardCount - 1

        it 'should remove the card from the backlog column', ->
          expect(_.pluck(@backlogColumn.getCards(), 'id')).toNotContain(@card.getId())

        it 'should have correct card count in left column', ->
          expect(@leftColumn.getCards().length).toBe @leftCardCount + 1

        it 'should place the card in the correct location', ->
          expect(@leftColumn.getCards()[3].getId()).toEqual @card.getId()

        it 'should send rankBelow', ->
          expect(@destPlanRecordSaveStub.lastCall.args[0].params.rankBelow).toContain '1002'

        it 'should update plan record', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)

      describe 'from bottom to top', ->

        beforeEach ->
          @backlogCardCount = @backlogColumn.getCards().length
          @leftCardCount = @leftColumn.getCards().length
          @card = @backlogColumn.getCards()[1]

          @dragCard
            sourceColumn: @backlogColumn
            destColumnDropController: @leftColumnDropController
            sourceIndex: 1
            destIndex: 0

        it 'should have correct card count in backlog column', ->
          expect(@backlogColumn.getCards().length).toBe @backlogCardCount - 1

        it 'should remove the card from the backlog column', ->
          expect(_.pluck(@backlogColumn.getCards(), 'id')).toNotContain(@card.getId())

        it 'should have correct card count in left column', ->
          expect(@leftColumn.getCards().length).toBe @leftCardCount + 1

        it 'should place the card in the correct location', ->
          expect(@leftColumn.getCards()[0].getId()).toEqual @card.getId()

        it 'should call the save method of the left column', ->
          expect(@destPlanRecordSaveStub).toHaveBeenCalledOnce()

        it 'should send rankAbove', ->
          expect(@destPlanRecordSaveStub.lastCall.args[0].params.rankAbove).toContain '1000'

        it 'should update plan record', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)

    describe 'within a plan', ->

      describe 'from top to bottom', ->

        beforeEach ->
          @cardLengthBefore = @leftColumn.getCards().length
          @card = @leftColumn.getCards()[0]
          @dragCard
            sourceColumn: @leftColumn
            destColumnDropController: @leftColumnDropController
            sourceIndex: 0
            destIndex: 3

        it 'should have the correct number of cards', ->
          expect(@leftColumn.getCards().length).toBe @cardLengthBefore

        it 'should place the card in the correct location', ->
          expect(@leftColumn.getCards()[2].getId()).toEqual @card.getId()

        it 'should have correct url', ->
          planId = @leftColumn.planRecord.getId()
          expect(@ajaxRequest.lastCall.args[0].url).toContain "#{planId}/features/to/#{planId}"

        it 'should send rankBelow', ->
          expect(@ajaxRequest.lastCall.args[0].params.rankBelow).toContain '1002'

        it 'should update plan record', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)

      describe 'from top to middle', ->

        beforeEach ->
          @cardLengthBefore = @leftColumn.getCards().length
          @card = @leftColumn.getCards()[0]
          @dragCard
            sourceColumn: @leftColumn
            destColumnDropController: @leftColumnDropController
            sourceIndex: 0
            destIndex: 2

        it 'should have the correct number of cards', ->
          expect(@leftColumn.getCards().length).toBe @cardLengthBefore

        it 'should place the card in the correct location', ->
          expect(@leftColumn.getCards()[1].getId()).toEqual @card.getId()

        it 'should have correct url', ->
          planId = @leftColumn.planRecord.getId()
          expect(@ajaxRequest.lastCall.args[0].url).toContain "#{planId}/features/to/#{planId}"

        it 'should send rankBelow', ->
          expect(@ajaxRequest.lastCall.args[0].params.rankBelow).toContain '1001'

        it 'should update plan record', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)

      describe 'from bottom to top', ->

        beforeEach ->
          @cardLengthBefore = @leftColumn.getCards().length
          @card = @leftColumn.getCards()[2]
          @dragCard
            sourceColumn: @leftColumn
            destColumnDropController: @leftColumnDropController
            sourceIndex: 2
            destIndex: 0

        it 'should have the correct number of cards', ->
          expect(@leftColumn.getCards().length).toBe @cardLengthBefore

        it 'should place the card in the correct location', ->
          expect(@leftColumn.getCards()[0].getId()).toEqual @card.getId()

        it 'should call the save method of the left column', ->
          planId = @leftColumn.planRecord.getId()
          expect(@ajaxRequest.lastCall.args[0].url).toContain "#{planId}/features/to/#{planId}"

        it 'should send rankAbove', ->
          expect(@ajaxRequest.lastCall.args[0].params.rankAbove).toContain '1000'

        it 'should update plan record', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)

    describe 'from plan to plan', ->

      describe 'from top to top', ->

        beforeEach ->
          @leftCardCount = @leftColumn.getCards().length
          @rightCardCount = @rightColumn.getCards().length
          @card = @leftColumn.getCards()[0]

          @dragCard
            sourceColumn: @leftColumn
            destColumnDropController: @rightColumnDropController
            sourceIndex: 0
            destIndex: 0

        it 'should have correct card count in left column', ->
          expect(@leftColumn.getCards().length).toBe @leftCardCount - 1

        it 'should remove the card from the backlog column', ->
          expect(_.pluck(@leftColumn.getCards(), 'id')).toNotContain(@card.getId())

        it 'should have correct card count in right column', ->
          expect(@rightColumn.getCards().length).toBe @rightCardCount + 1

        it 'should place the card in the correct location', ->
          expect(@rightColumn.getCards()[0].getId()).toEqual @card.getId()

        it 'should have correct url', ->
          srcPlanId = @leftColumn.planRecord.getId()
          destPlanId = @rightColumn.planRecord.getId()
          expect(@ajaxRequest.lastCall.args[0].url).toContain "#{srcPlanId}/features/to/#{destPlanId}"

        it 'should send rankAbove', ->
          expect(@ajaxRequest.lastCall.args[0].params.rankAbove).toContain '1005'

        it 'should commit changes for both plans', ->
          expect(@rightColumn.planRecord.dirty).toBe false
          expect(@leftColumn.planRecord.dirty).toBe false

        it 'should update plan record', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)
          @expectPlanFeaturesToMatchCards(@rightColumn)

      describe 'from top to bottom', ->

        beforeEach ->
          @leftCardCount = @leftColumn.getCards().length
          @rightCardCount = @rightColumn.getCards().length
          @card = @leftColumn.getCards()[0]

          @dragCard
            sourceColumn: @leftColumn
            destColumnDropController: @rightColumnDropController
            sourceIndex: 0
            destIndex: 2

        it 'should have correct card count in left column', ->
          expect(@leftColumn.getCards().length).toBe @leftCardCount - 1

        it 'should remove the card from the backlog column', ->
          expect(_.pluck(@leftColumn.getCards(), 'id')).toNotContain(@card.getId())

        it 'should have correct card count in right column', ->
          expect(@rightColumn.getCards().length).toBe @rightCardCount + 1

        it 'should place the card in the correct location', ->
          expect(@rightColumn.getCards()[2].getId()).toEqual @card.getId()

        it 'should have correct url', ->
          srcPlanId = @leftColumn.planRecord.getId()
          destPlanId = @rightColumn.planRecord.getId()
          expect(@ajaxRequest.lastCall.args[0].url).toContain "#{srcPlanId}/features/to/#{destPlanId}"

        it 'should send rankBelow', ->
          expect(@ajaxRequest.lastCall.args[0].params.rankBelow).toContain '1006'

        it 'should update plan records', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)
          @expectPlanFeaturesToMatchCards(@rightColumn)

      describe 'from bottom to top', ->

        beforeEach ->
          @leftCardCount = @leftColumn.getCards().length
          @rightCardCount = @rightColumn.getCards().length
          @card = @leftColumn.getCards()[2]

          @dragCard
            sourceColumn: @leftColumn
            destColumnDropController: @rightColumnDropController
            sourceIndex: 2
            destIndex: 0

        it 'should have correct card count in left column', ->
          expect(@leftColumn.getCards().length).toBe @leftCardCount - 1

        it 'should remove the card from the backlog column', ->
          expect(_.pluck(@leftColumn.getCards(), 'id')).toNotContain(@card.getId())

        it 'should have correct card count in right column', ->
          expect(@rightColumn.getCards().length).toBe @rightCardCount + 1

        it 'should place the card in the correct location', ->
          expect(@rightColumn.getCards()[0].getId()).toEqual @card.getId()

        it 'should have correct url', ->
          srcPlanId = @leftColumn.planRecord.getId()
          destPlanId = @rightColumn.planRecord.getId()
          expect(@ajaxRequest.lastCall.args[0].url).toContain "#{srcPlanId}/features/to/#{destPlanId}"

        it 'should send rankAbove', ->
          expect(@ajaxRequest.lastCall.args[0].params.rankAbove).toContain '1005'

        it 'update plan records', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)
          @expectPlanFeaturesToMatchCards(@rightColumn)

    describe 'from plan to backlog', ->

      describe 'from top to top', ->

        beforeEach ->
          @leftCardCount = @leftColumn.getCards().length
          @backlogCardCount = @backlogColumn.getCards().length
          @card = @leftColumn.getCards()[0]

          @dragCard
            sourceColumn: @leftColumn
            destColumnDropController: @backlogColumnDropController
            backlogColumn: @backlogColumn
            sourceIndex: 0
            destIndex: 0

        it 'should have correct card count in left column', ->
          expect(@leftColumn.getCards().length).toBe @leftCardCount - 1

        it 'should remove the card from the left column', ->
          expect(_.pluck(@leftColumn.getCards(), 'id')).toNotContain(@card.getId())

        it 'should have correct card count in backlog column', ->
          expect(@backlogColumn.getCards().length).toBe @backlogCardCount + 1

        it 'should place the card in the correct location', ->
          expect(@backlogColumn.getCards()[0].getId()).toEqual @card.getId()

        it 'should call the save method of the left column', ->
          expect(@sourcePlanRecordSaveStub).toHaveBeenCalledOnce()

        it 'should update plan record', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)

      describe 'from top to bottom', ->

        beforeEach ->
          @leftCardCount = @leftColumn.getCards().length
          @backlogCardCount = @backlogColumn.getCards().length
          @card = @leftColumn.getCards()[0]

          @dragCard
            sourceColumn: @leftColumn
            destColumnDropController: @backlogColumnDropController
            backlogColumn: @backlogColumn
            sourceIndex: 0
            destIndex: 2

        it 'should have correct card count in left column', ->
          expect(@leftColumn.getCards().length).toBe @leftCardCount - 1

        it 'should remove the card from the left column', ->
          expect(_.pluck(@leftColumn.getCards(), 'id')).toNotContain(@card.getId())

        it 'should have correct card count in backlog column', ->
          expect(@backlogColumn.getCards().length).toBe @backlogCardCount + 1

        it 'should place the card in the correct location', ->
          expect(@backlogColumn.getCards()[2].getId()).toEqual @card.getId()

        it 'should update plan record', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)

      describe 'from bottom to top', ->

        beforeEach ->
          @leftCardCount = @leftColumn.getCards().length
          @backlogCardCount = @backlogColumn.getCards().length
          @card = @leftColumn.getCards()[2]

          @dragCard
            sourceColumn: @leftColumn
            destColumnDropController: @backlogColumnDropController
            backlogColumn: @backlogColumn
            sourceIndex: 2
            destIndex: 0

        it 'should have correct card count in left column', ->
          expect(@leftColumn.getCards().length).toBe @leftCardCount - 1

        it 'should remove the card from the left column', ->
          expect(_.pluck(@leftColumn.getCards(), 'id')).toNotContain(@card.getId())

        it 'should have correct card count in backlog column', ->
          expect(@backlogColumn.getCards().length).toBe @backlogCardCount + 1

        it 'should place the card in the correct location', ->
          expect(@backlogColumn.getCards()[0].getId()).toEqual @card.getId()

        it 'should call the save method of the left column', ->
          expect(@sourcePlanRecordSaveStub).toHaveBeenCalledOnce()

        it 'should update plan record', ->
          @expectPlanFeaturesToMatchCards(@leftColumn)

  describe '#_onDropSaveFailure', ->

    beforeEach ->
      @leftColumn.ownerCardboard.refresh = =>
      @cardboardRefreshStub = @stub @leftColumn.ownerCardboard, 'refresh'
      @leftColumnDropController._onDropSaveFailure()

    it 'should refresh the cardboard', ->
      expect(@cardboardRefreshStub).toHaveBeenCalledOnce()

    it 'should set rebuildBoard to true when refreshing the board', ->
      expect(@cardboardRefreshStub.lastCall.args[0].rebuildBoard).toBe true

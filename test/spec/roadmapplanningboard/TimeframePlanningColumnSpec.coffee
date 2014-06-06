Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.TimeframePlanningColumn'
  'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper'
]

describe 'Rally.apps.roadmapplanningboard.TimeframePlanningColumn', ->

  helpers
    createColumn: (config = {}) ->
      config.useInMemoryStore ?= true

      if config.useInMemoryStore
        config.store = Deft.Injector.resolve 'featureStore'

      @columnReadyStub = @stub()
      @column = Ext.create 'Rally.apps.roadmapplanningboard.TimeframePlanningColumn',
        Ext.merge {},
          contentCell: 'testDiv'
          headerCell: 'testDiv'
          displayValue: 'My column'
          headerTemplate: Ext.create 'Ext.XTemplate'
          timeframeRecord: @timeframeRecord
          planRecord: @planRecord
          timeframePlanStoreWrapper: @createTimeframePlanWrapper()
          ownerCardboard:
            showTheme: true
          editPermissions:
            capacityRanges: true
            theme: true
            timeframeDates: true
            deletePlan: true
          columnHeaderConfig:
            editable: true
            record: @timeframeRecord
            fieldToDisplay: 'name'
          renderTo: 'testDiv'
          cardConfig: fields: ['RefinedEstimate', 'PreliminaryEstimate']
          typeNames:
            child:
              name: 'Feature'
          listeners:
            ready: =>
              @columnReadyStub()
            deleteplan: => @deletePlanStub()
            daterangechange: => @dateRangeChangeStub()
          filterCollection: Ext.create 'Rally.data.filter.FilterCollection'
        , config
      @waitForColumnReady()

    createPlanRecord: (config) ->
      @planRecord = Ext.create Rally.apps.roadmapplanningboard.AppModelFactory.getPlanModel(),
        _.extend
          id: 'Foo',
          name: 'Q1',
          theme: 'Take over the world!'
          lowCapacity: 0
          highCapacity: 0
          features: []
        , config

    createTimeframeRecord: (config) ->
      @timeframeRecord = Ext.create Rally.apps.roadmapplanningboard.AppModelFactory.getTimeframeModel(),
        _.extend
          name: 'Q1'
          startDate: new Date('04/01/2013')
          endDate: new Date('06/30/2013')
        , config

    createTimeframePlanWrapper: ->
      Ext.create 'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper',
        timeframeStore: Deft.Injector.resolve 'timeframeStore'
        planStore: Deft.Injector.resolve 'planStore'

    clickDeleteButton: ->
      @column.deletePlanButton.fireEvent 'click', @column.deletePlanButton
      @confirmDialog = Ext.ComponentQuery.query('rallyconfirmdialog')[0]

    refreshColumn: ->
      @refreshCount ?= 0
      @column.refresh store: @column.store
      @refreshCount++
      @waitForColumnReady @refreshCount + 1

    waitForColumnReady: (callCount = 1) ->
      @once
        condition: =>
          @columnReadyStub.callCount >= callCount

    createColumnUsingAjax: (options) ->
      @createColumn Ext.merge(
        fields: ['FormattedID', 'Name']
        types: ['PortfolioItem/Feature']
        model: 'PortfolioItem/Feature'
        useInMemoryStore: false
      , options)

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @deletePlanStub = @stub()
    @dateRangeChangeStub = @stub()

  afterEach ->
    Deft.Injector.reset()
    @column?.destroy()

  describe 'timeframe column', ->
    beforeEach ->
      @createTimeframeRecord()
      @createPlanRecord
        lowCapacity: 22
        highCapacity: 42

    it 'should have a timeframe added to the header template', ->
      @createColumn().then =>
        headerTplData = @column.getDateHeaderTplData()

        expect(headerTplData['formattedDate']).toEqual 'Apr 1 - Jun 30'

    it 'should render a thermometer in the header template (unfiltered data)', ->
      @createColumn().then =>
        @column.isMatchingRecord = -> true

        @refreshColumn().then =>
          headerTplData = @column.getHeaderTplData()
          expect(headerTplData['progressBarHtml']).toContain '74 of 42'

    it 'should render a thermometer in the header template (filtered data)', ->
      @createColumn().then =>
        @column.isMatchingRecord = (record) ->
          record.data.Name.indexOf('Android') > -1 || record.data.Name.indexOf('iOS') > -1

        @refreshColumn().then =>
          headerTplData = @column.getHeaderTplData()
          expect(headerTplData['progressBarHtml']).toContain '9 of 42'

    it 'should handle empty values as spaces', ->
      @createTimeframeRecord
        startDate: null
        endDate: null
      @createPlanRecord
        lowCapacity: 0
        highCapacity: 0

      @createColumn().then =>
        @refreshColumn().then =>
          headerTplData = @column.getHeaderTplData()

          expect(headerTplData['formattedStartDate']).toEqual(undefined)
          expect(headerTplData['formattedEndDate']).toEqual(undefined)
          expect(headerTplData['formattedPercent']).toEqual("0%")
          expect(headerTplData['progressBarHtml']).toBeTruthy()

  describe 'loading features from store', ->
    beforeEach ->
      @createTimeframeRecord()
      @createPlanRecord()
      features = Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.featureStoreData
      @ajaxSpy = @ajax.whenQuerying('PortfolioItem/Feature').respondWith(features)

    it 'should only load the store once when the column is created', ->
      @createColumnUsingAjax().then =>
        expect(@ajaxSpy.callCount).toBe 1

    it 'should add a plan features filter', ->
      @createColumnUsingAjax().then =>
        expect(@column.filterCollection.tempFilters.planfeatures).not.toBeNull()

    describe 'with shallow fetch enabled', ->

      helpers
        createColumnWithShallowFetchEnabled: ->
          @createColumnUsingAjax(storeConfig: useShallowFetch: true)
          @waitForCallback(@ajaxSpy)

      it 'should set the shallowFetch param in the request', ->
        @createColumnWithShallowFetchEnabled().then =>
          expect(@ajaxSpy.lastCall.args[0].params.shallowFetch).toBeDefined()

      it 'should not set the fetch param in the request', ->
        @createColumnWithShallowFetchEnabled().then =>
          expect(@ajaxSpy.lastCall.args[0].params.fetch).toBeUndefined()

    describe 'with shallow fetch disabled', ->
      
      helpers
        createColumnWithShallowFetchDisabled: ->
          @createColumnUsingAjax(storeConfig: useShallowFetch: false)
          @waitForCallback(@ajaxSpy)

      it 'should not set the shallowFetch param in the request', ->
        @createColumnWithShallowFetchDisabled().then =>
          expect(@ajaxSpy.lastCall.args[0].params.shallowFetch).toBeUndefined()

      it 'should set the fetch param in the request', ->
        @createColumnWithShallowFetchDisabled().then =>
          expect(@ajaxSpy.lastCall.args[0].params.fetch).toBeDefined()


  describe '#getStoreFilter', ->

    beforeEach ->
      @createTimeframeRecord()
      @createPlanRecord()
      @createColumn()

    it 'should return null', ->
      expect(this.column.getStoreFilter()).toBeNull()

  describe 'progress bar', ->

    beforeEach ->
      @createTimeframeRecord()
      @createPlanRecord()

    describe 'with no capacity', ->

      it 'should display a popover when clicked if editing is allowed', ->
        @createColumn().then =>
          expect(!!@column.popover).toBe false
          @click(this.column.getColumnHeader().getEl().down('.add-capacity span')).then =>
            expect(!!@column.popover).toBe true

      it 'should not enable the planned capacity tooltip when destroying the capacity popover', ->
        @createColumn().then =>
          expect(!!@column.popover).toBe false
          expect(@column.plannedCapacityRangeTooltip.isDisabled()).toBe true
          @click(this.column.getColumnHeader().getEl().down('.add-capacity span')).then =>
            expect(!!@column.popover).toBe true
            expect(@column.plannedCapacityRangeTooltip.isDisabled()).toBe true
            @column.popover.destroy()
            expect(@column.plannedCapacityRangeTooltip.isDisabled()).toBe true

      it 'should not display a set capacity button if editing is not allowed', ->
        @createColumn(
          editPermissions:
            capacityRanges: false
        ).then =>
          expect(Ext.query('.add-capacity span')).toEqual []

      it 'should disable the planned capacity tooltip on mouseover', ->
        @createColumn().then =>
          expect(@column.plannedCapacityRangeTooltip.isDisabled()).toBe true
          expect(@column.plannedCapacityRangeTooltip.isVisible()).toBe false

    describe 'with capacity', ->
      beforeEach ->
        @planRecord.set('highCapacity', 10)

      it 'should display a popover when clicked if editing is allowed', ->
        @createColumn().then =>
          expect(!!@column.popover).toBe false
          @click(this.column.getColumnHeader().getEl().down('.progress-bar-container')).then =>
            expect(!!@column.popover).toBe true

      it 'should disable the planned capacity tooltip when clicking the progress bar', ->
        @createColumn().then =>
          expect(!!@column.popover).toBe false
          expect(@column.plannedCapacityRangeTooltip.isDisabled()).toBe false
          @click(this.column.getColumnHeader().getEl().down('.progress-bar-container')).then =>
            expect(!!@column.popover).toBe true
            expect(@column.plannedCapacityRangeTooltip.isDisabled()).toBe true

      it 'should enable the planned capacity tooltip when destroying the capacity popover', ->
        @createColumn().then =>
          expect(!!@column.popover).toBe false
          expect(@column.plannedCapacityRangeTooltip.isDisabled()).toBe false
          @click(this.column.getColumnHeader().getEl().down('.progress-bar-container')).then =>
            expect(@column.plannedCapacityRangeTooltip.isDisabled()).toBe true
            @column.popover.destroy()
            expect(@column.plannedCapacityRangeTooltip.isDisabled()).toBe false

      it 'should not display a popover when clicked if editing is not allowed', ->
        @createColumn(
          editPermissions:
            capacityRanges: false
        ).then =>
          expect(@column.popover).toBeUndefined()
          @click(this.column.getColumnHeader().getEl().down('.progress-bar-container')).then =>
            expect(!!@column.popover).toBe false

  describe 'theme header', ->
    beforeEach ->
      @createTimeframeRecord()
      @createPlanRecord()

    it 'should render a single theme header', ->
      @createColumn().then =>
        expect(@column.getColumnHeader().query('roadmapthemeheader').length).toBe 1

    it 'should have an editable theme header', ->
      @createColumn().then =>
        theme = @column.getColumnHeader().query('roadmapthemeheader')[0]
        if !Ext.isGecko
          @click(theme.getEl()).then =>
            expect(!!theme.getEl().down('textarea')).toBe true

    it 'should have an uneditable theme header', ->
      @createColumn(
        editPermissions:
          theme: false
      ).then =>
        theme = @column.getColumnHeader().query('roadmapthemeheader')[0]
        @click(theme.getEl()).then =>
          expect(!!theme.getEl().down('textarea')).toBe false

  describe 'title header', ->
    beforeEach ->
      @createPlanRecord()
      @createTimeframeRecord()

    it 'should have an editable title', ->
      @createColumn().then =>

        title = @column.getHeaderTitle().down().getEl()

        @click(title).then =>
          expect(!!title.down('input')).toBe true

    it 'should have an uneditable title', ->
      @createColumn(
        columnHeaderConfig:
          editable: false
      ).then =>
        title = @column.getHeaderTitle().down().getEl()

        @click(title).then =>
          expect(!!title.down('input')).toBe false

  describe 'timeframe dates', ->

    beforeEach ->
      @createPlanRecord()
      @createTimeframeRecord()

    it 'should have an editable timeframe date', ->
      @createColumn().then =>
        dateRange = @column.dateRange.getEl()
        if !Ext.isGecko
          @click(dateRange).then =>
            expect(!!@column.timeframePopover).toBe true

    it 'should have an uneditable timeframe date', ->
      @createColumn(
        editPermissions:
          timeframeDates: false
      ).then =>
        dateRange = @column.dateRange.getEl()
        @click(dateRange).then =>
          expect(!!@column.timeframePopover).toBe false

    describe 'when timeframe dates popover fires the save event', ->

      beforeEach ->
        @saveSpy = @spy @timeframeRecord, 'save'
        @createColumn().then =>
          @column.onTimeframeDatesClick target: @column.dateRange.getEl()
          @column.timeframePopover.fireEvent 'save'

      it 'should save the timeframeRecord', ->
        expect(@saveSpy).toHaveBeenCalledOnce()

      it 'should fire the daterangechange event on the column', ->
        expect(@dateRangeChangeStub).toHaveBeenCalledOnce()

    describe 'timeframe date tooltip', ->

      it 'should have a timeframe date tooltip if user has edit permissions', ->
        @createColumn(
          editPermissions:
            timeframeDates: true
        ).then =>
          expect(@column.dateRangeTooltip).toBeDefined()

      it 'should not have a timeframe date tooltip if user does not have edit permissions', ->
        @createColumn(
          editPermissions:
            timeframeDates: false
        ).then =>
          expect(this.column.dateRangeTooltip).toBeUndefined()

  describe 'header buttons', ->

    beforeEach ->
      @createPlanRecord()
      @createTimeframeRecord()

    describe 'delete plan button', ->

      it 'should show the delete plan button if the user has edit permissions', ->
        @createColumn(editPermissions: { deletePlan: true }).then =>
          expect(@column.deletePlanButton).toBeDefined()

      it 'should not show the delete plan button if the user does not have edit permissions', ->
        @createColumn(editPermissions: { deletePlan: false }).then =>
          expect(!!@column.deletePlanButton).toBe false

      describe 'when clicked', ->

        describe 'on column with features', ->

          beforeEach ->
            @createPlanRecord features: [{id: 1}, {id: 2}]
            @createColumn(editPermissions: deletePlan: true).then =>
              @clickDeleteButton()

          it 'should not fire the deleteplan event', ->
            expect(@deletePlanStub).not.toHaveBeenCalled()

          it 'should show a confirmation dialog', ->
            expect(!!@confirmDialog).toBe true

          describe 'confirmation dialog', ->

            it 'should fire deleteplan when clicking Delete', ->
              @confirmDialog.down('#confirmButton').fireEvent 'click'
              expect(@deletePlanStub).toHaveBeenCalledOnce()

            it 'should not fire deleteplan when clicking Cancel', ->
              @confirmDialog.down('#cancelButton').fireEvent 'click'
              expect(@deletePlanStub).not.toHaveBeenCalled()

        describe 'on column without features', ->

          beforeEach ->
            @createColumn(editPermissions: { deletePlan: true }).then =>
              @clickDeleteButton()

          it 'should fire the deleteplan event', ->
            expect(@deletePlanStub).toHaveBeenCalledOnce()

          it 'should not show a confirmation dialog', ->
            expect(!!@confirmDialog).toBe false


  describe 'capacity calculation', ->
    beforeEach ->
      @createPlanRecord()
      @createTimeframeRecord()
      @createColumn()

    it 'should use preliminary estimate if the card does not have a refined estimate or it is zero', ->
      @column.isMatchingRecord = (record) ->
        record.data.RefinedEstimate <= 0
      @refreshColumn().then =>
        expect(@column.getHeaderTplData().pointTotal).toEqual 59

    it 'should use refined estimate if the card has a refined estimate', ->
      @column.isMatchingRecord = (record) ->
        record.data.RefinedEstimate > 0
      @refreshColumn().then =>
        expect(@column.getHeaderTplData().pointTotal).toEqual 15

    it 'calculation should use refined before preliminary estimate', ->
      expect(@column.getHeaderTplData().pointTotal).toEqual 74

  describe '#filter', ->
    beforeEach ->
      @createTimeframeRecord()
      @createPlanRecord()
      @createColumnUsingAjax().then =>

    it 'should update plan features filter', ->
      originalFilter = @column.filterCollection.tempFilters.planfeatures
      @column.filter()
      expect(@column.filterCollection.tempFilters.planfeatures).not.toBe originalFilter

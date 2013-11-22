Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.TimeframePlanningColumn'
]

describe 'Rally.apps.roadmapplanningboard.TimeframePlanningColumn', ->

  helpers
    createColumn: (config) ->
      @column = Ext.create 'Rally.apps.roadmapplanningboard.TimeframePlanningColumn',
        Ext.merge {},
          contentCell: 'testDiv'
          headerCell: 'testDiv'
          displayValue: 'My column'
          headerTemplate: Ext.create 'Ext.XTemplate'
          timeframeRecord: @timeframeRecord
          store: @featureStoreFixture
          planRecord: @planRecord
          ownerCardboard:
            showTheme: true
          editPermissions:
            capacityRanges: true
            theme: true
            timeframeDates: true
          columnHeaderConfig:
            editable: true
            record: @timeframeRecord
            fieldToDisplay: 'name'
          renderTo: 'testDiv'
        , config

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
          start: new Date('04/01/2013')
          end: new Date('06/30/2013')
        , config

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()
    @featureStoreFixture = Deft.Injector.resolve 'featureStore'

  afterEach ->
    Deft.Injector.reset()
    @column.destroy()

  describe 'timeframe column', ->
    beforeEach ->
      @createTimeframeRecord()
      @createPlanRecord
        lowCapacity: 22
        highCapacity: 42

    afterEach ->
      @column.destroy()

    it 'should have a timeframe added to the header template', ->
      @createColumn()
      headerTplData = @column.getDateHeaderTplData()

      expect(headerTplData['formattedDate']).toEqual 'Apr 1 - Jun 30'

    it 'should render a thermometer in the header template (unfiltered data)', ->
      @createColumn()
      @column.isMatchingRecord = ->
        true

      @column.refresh()

      headerTplData = @column.getHeaderTplData()

      expect(headerTplData['progressBarHtml']).toContain '72 of 42'

    it 'should render a thermometer in the header template (filtered data)', ->
      @createColumn()
      @column.isMatchingRecord = (record) ->
        record.data.Name.indexOf('Android') > -1 || record.data.Name.indexOf('iOS') > -1

      @column.refresh()

      headerTplData = @column.getHeaderTplData()

      expect(headerTplData['progressBarHtml']).toContain '6 of 42'

    it 'should handle empty values as spaces', ->
      @createTimeframeRecord
        start: null
        end: null
      @createPlanRecord
        lowCapacity: 0
        highCapacity: 0

      @createColumn()

      @column.refresh()

      headerTplData = @column.getHeaderTplData()

      expect(headerTplData['formattedStartDate']).toEqual(undefined)
      expect(headerTplData['formattedEndDate']).toEqual(undefined)
      expect(headerTplData['formattedPercent']).toEqual("0%")
      expect(headerTplData['progressBarHtml']).toBeTruthy()

  describe '#getStoreFilter', ->
    beforeEach ->
      @createTimeframeRecord()

    afterEach ->
      @column.destroy()

    it 'should return an array of store filters if there are no features', ->
      @createPlanRecord()
      @createColumn()

      expect(this.column.getStoreFilter()).toEqual []

  describe 'progress bar', ->
    beforeEach ->
      @createTimeframeRecord()
      @createPlanRecord()

    afterEach ->
      @column.destroy()

    it 'should display a popover when clicked if editing is allowed', ->
      @createColumn()
      expect(!!@column.popover).toBe false
      @click(this.column.getColumnHeader().getEl().down('.progress-bar-container')).then =>
        expect(!!@column.popover).toBe true

    it 'should not display a popover when clicked if editing is not allowed', ->
      @createColumn
        editPermissions:
          capacityRanges: false

      expect(@column.popover).toBeUndefined()
      @click(this.column.getColumnHeader().getEl().down('.progress-bar-container')).then =>
        expect(!!@column.popover).toBe false

  describe 'theme header', ->
    beforeEach ->
      @createTimeframeRecord()
      @createPlanRecord()

    afterEach ->
      @column.destroy()

    it 'should render a single theme header', ->
      @createColumn()
      expect(@column.getColumnHeader().query('roadmapthemeheader').length).toBe 1

    it 'should have an editable theme header', ->
      @createColumn()
      theme = @column.getColumnHeader().query('roadmapthemeheader')[0]
      if !Ext.isGecko
        @click(theme.getEl()).then =>
          expect(!!theme.getEl().down('textarea')).toBe true

    it 'should have an uneditable theme header', ->
      @createColumn
        editPermissions:
          theme: false
      theme = @column.getColumnHeader().query('roadmapthemeheader')[0]
      @click(theme.getEl()).then =>
        expect(!!theme.getEl().down('textarea')).toBe false

  describe 'title header', ->
    beforeEach ->
      @createPlanRecord()
      @createTimeframeRecord()

    afterEach ->
      @column.destroy()

    it 'should have an editable title', ->
      @createColumn()

      title = @column.getHeaderTitle().down().getEl()

      @click(title).then =>
        expect(!!title.down('input')).toBe true

    it 'should have an uneditable title', ->
      @createColumn
        columnHeaderConfig:
          editable: false

      title = @column.getHeaderTitle().down().getEl()

      @click(title).then =>
        expect(!!title.down('input')).toBe false

  describe 'timeframe dates', ->
    beforeEach ->
      @createPlanRecord()
      @createTimeframeRecord()

    afterEach ->
      @column.destroy()

    it 'should have an editable timeframe date', ->
      @createColumn()
      dateRange = @column.dateRange.getEl()
      if !Ext.isGecko
        @click(dateRange).then =>
          expect(!!@column.timeframePopover).toBe true

    it 'should have an uneditable timeframe date', ->
      @createColumn
        editPermissions:
          timeframeDates: false
      dateRange = @column.dateRange.getEl()
      @click(dateRange).then =>
        expect(!!@column.timeframePopover).toBe false

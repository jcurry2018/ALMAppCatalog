Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.nav.Manager',
  'Rally.util.DateTime',
  'Rally.util.Ref'
]

describe 'Rally.apps.releasesummary.ReleaseSummaryApp', ->
  beforeEach ->
    @releases = @mom.getData('release',
      values: [
        _ref: '/release/1',
        Name: 'Release 1',
        Notes: 'Release 1 Note',
        ReleaseStartDate: Rally.util.DateTime.add(new Date(), 'day', -5),
        ReleaseDate: Rally.util.DateTime.add(new Date(), 'day', 5)
      ,
        _ref: '/release/2',
        Name: 'Release 2',
        Notes: '',
        ReleaseStartDate: '2013-09-03',
        ReleaseDate: '2013-09-04'
      ]
    )
    @ajax.whenQuerying('release').respondWith @releases
    _.each @releases, (release) ->
      @ajax.whenReading('release', Rally.util.Ref.getOidFromRef(release)).respondWith release

    @stories = @mom.getData('userstory', {count: 2})
    @ajax.whenQuerying('userstory').respondWith @stories

    @defects = @mom.getData('defect', {count: 2})
    @ajax.whenQuerying('defect').respondWith @defects

    @ajax.whenQueryingAllowedValues('userstory', 'ScheduleState').respondWith(["Defined", "In-Progress", "Completed", "Accepted"])
    @ajax.whenQueryingAllowedValues('defect', 'ScheduleState').respondWith(["Defined", "In-Progress", "Completed", "Accepted"])

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'releasesummaryapp'

  it 'should display About this release', ->
    @createApp().then =>
      expect(@getReleaseInfoHTML()).toContain 'About this release:'

  it 'should display the release notes', ->
    @createApp().then =>
      scope = @app.getContext().getTimeboxScope().getRecord()
      expect(@getReleaseInfoHTML()).toContain scope.get('Notes')

  it 'should create correct link for additional release information', ->
    @createApp().then =>
      record = @app.getContext().getTimeboxScope().getRecord().get('_ref')
      detailUrl = Rally.nav.Manager.getDetailUrl(record)

      expect(@getReleaseInfoHTML()).toContain detailUrl

  it 'should get correct store filters for grid', ->
    @createApp().then =>
      storyFilter = @app.down('#story-grid').getStore().filters.items[0].toString()
      defectFilter = @app.down('#defect-grid').getStore().filters.items[0].toString()

      expect(storyFilter).toContain "(Release.Name = \"#{@releases[0].Name}\")"
      expect(defectFilter).toContain "(Release.Name = \"#{@releases[0].Name}\")"

  it 'should re-filter grids every time scope is changed', ->
    @createApp().then =>
      releaseRecord = @mom.getRecord 'release'
      @ajax.whenReading('release', Rally.util.Ref.getOidFromRef(releaseRecord)).respondWith @mom.getData('release')[0]
      newTimeboxScope = Ext.create 'Rally.app.TimeboxScope', record: releaseRecord

      @stories = @mom.getData('userstory', {count: 3})
      @ajax.whenQuerying('userstory').respondWith @stories
      filterSpy = @spy @app.down('rallytreegrid').getStore(), 'filter'
      Rally.environment.getMessageBus().publish(Rally.app.Message.timeboxScopeChange, newTimeboxScope)

      @once(
        condition: => filterSpy.callCount == 1
      ).then =>
        args = filterSpy.firstCall.args
        expect(args[0].length).toBe 1
        expect(args[0][0].toString()).toBe newTimeboxScope.getQueryFilter().toString()

        expect(@app.getContext().getTimeboxScope().getRecord()).toEqual releaseRecord
        expect(@app.down('#story-grid').getEl().query('.' + Ext.baseCSSPrefix + 'grid-data-row').length).toBe 3

  it 'should show correct # stories in grid title', ->
    @createApp().then =>
      @app.down('#story-grid').getStore().load()
      expect(@app.down('#story-grid').title).toBe "Stories: #{@stories.length}"

  it 'should show correct # defects in grid title', ->
    @createApp().then =>
      @app.down('#defect-grid').getStore().load()
      expect(@app.down('#defect-grid').title).toBe "Defects: #{@defects.length}"

  it 'should call _refreshGrids when timebox combobox is changed', ->
    @createApp().then =>
      storyFilterSpy = @spy(@app.down('#story-grid').getStore(), 'filter')
      defectFilterSpy = @spy(@app.down('#defect-grid').getStore(), 'filter')

      @clickLeftTimeboxButton()
      expect(storyFilterSpy.callCount).toBe 1
      expect(defectFilterSpy.callCount).toBe 1

      @clickRightTimeboxButton()
      expect(storyFilterSpy.callCount).toBe 2
      expect(defectFilterSpy.callCount).toBe 2

  it 'should destroy grids when the unscheduled timebox option is selected and on a release scoped dashboard', ->
    @createApp(supportsUnscheduled: true).then =>
      @app.onNoAvailableTimeboxes()
      @once(
        condition: -> Ext.getBody().query('.rally-grid').length == 0
      )

  helpers
    createApp: (config={}) ->
      @app = Ext.create 'Rally.apps.releasesummary.ReleaseSummaryApp', Ext.apply
        renderTo: 'testDiv'
        context: @getContext()
      , config
      @once(
        condition: -> Ext.getBody().query('.rally-grid').length == 2
      )

    getContext: ->
      globalContext = Rally.environment.getContext()

      Ext.create 'Rally.app.Context',
        initialValues:
          project:globalContext.getProject()
          workspace:globalContext.getWorkspace()
          user:globalContext.getUser()
          subscription:globalContext.getSubscription()

    clickLeftTimeboxButton: ->
      @app.getEl().down('.combobox-left-arrow').dom.click()

    clickRightTimeboxButton: ->
      @app.getEl().down('.combobox-right-arrow').dom.click()

    getReleaseInfoHTML: ->
      @app.down('#release-info').getEl().getHTML()

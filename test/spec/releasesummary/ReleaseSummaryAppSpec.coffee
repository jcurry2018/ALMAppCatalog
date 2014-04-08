Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.app.TimeboxScope',
  'Rally.nav.Manager',
  'Rally.util.DateTime'
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

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'releasesummaryapp'

  it 'should display About this release', ->
    @createApp().then =>
      expect(@app.down('#releaseInfo').getEl().dom.innerHTML).toContain 'About this release:'

  it 'should display the release notes', ->
    @createApp().then =>
      scope = @app.getContext().getTimeboxScope().getRecord()
      expect(@app.down('#releaseInfo').getEl().dom.innerHTML).toContain scope.get('Notes')

  it 'should create correct link for additional release information', ->
    @createApp().then =>
      record = @app.getContext().getTimeboxScope().getRecord().get('_ref')
      detailUrl = Rally.nav.Manager.getDetailUrl(record)

      expect(@app.down('#releaseInfo').getEl().dom.innerHTML).toContain detailUrl

  it 'should get correct store filters for grid', ->
    @createApp().then =>
      storyFilter = @app.down('#story-grid').storeConfig.filters[0].toString()
      defectFilter = @app.down('#defect-grid').storeConfig.filters[0].toString()

      expect(storyFilter).toContain "(Release.Name = \"#{@releases[0].Name}\")"
      expect(defectFilter).toContain "(Release.Name = \"#{@releases[0].Name}\")"

  it 'should re-filter grids every time scope is changed', ->
    @createApp().then =>
      releaseRecord = @mom.getRecord 'release'
      newTimeboxScope = Ext.create 'Rally.app.TimeboxScope', record: releaseRecord
      filterSpy = @spy @app.down('rallygrid'), 'filter'

      Rally.environment.getMessageBus().publish(Rally.app.Message.timeboxScopeChange, newTimeboxScope)

      expect(@app.getContext().getTimeboxScope().getRecord()).toEqual releaseRecord

      expect(filterSpy).toHaveBeenCalledOnce()
      args = filterSpy.firstCall.args
      expect(args[0].length).toBe 1
      expect(args[0][0].toString()).toBe newTimeboxScope.getQueryFilter().toString()
      expect(args[1]).toBe true
      expect(args[2]).toBe true

  it 'should show correct # stories in grid title', ->
    @createApp().then =>
      expect(@app.down('#story-title').html).toBe "Stories: #{@stories.length}"

  it 'should show correct # defects in grid title', ->
    @createApp().then =>
      expect(@app.down('#defect-title').html).toBe "Defects: #{@defects.length}"

  it 'should call _refreshGrids when timebox combobox is changed', ->
    @createApp().then =>
      storyFilterSpy = @spy(@app.down('#story-grid'), 'filter')
      defectFilterSpy = @spy(@app.down('#defect-grid'), 'filter')

      @clickLeftTimeboxButton()
      expect(storyFilterSpy.callCount).toBe 1
      expect(defectFilterSpy.callCount).toBe 1

      @clickRightTimeboxButton()
      expect(storyFilterSpy.callCount).toBe 2
      expect(defectFilterSpy.callCount).toBe 2

  helpers
    createApp: ->
      @app = Ext.create 'Rally.apps.releasesummary.ReleaseSummaryApp',
        renderTo: 'testDiv'
        context: @getContext()
      @waitForComponentReady @app

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
Ext = window.Ext4 || window.Ext

Ext.require(['Rally.data.PreferenceManager'])

describe 'Rally.apps.customlist.CustomListApp', ->
  helpers
    createApp: (config) ->
      @showSettingsStub = @stub()

      @app = Ext.create 'Rally.apps.customlist.CustomListApp', _.merge
        appContainer: {}
        context: Ext.create 'Rally.app.Context',
          initialValues:
            permissions: Rally.environment.getContext().getPermissions()
            project: Rally.environment.getContext().getProject()
            subscription: Rally.environment.getContext().getSubscription()
            user: Rally.environment.getContext().getUser()
            workspace: Rally.environment.getContext().getWorkspace()
        height: 500
        owner:
          dashboard: {}
          showSettings: @showSettingsStub
        renderTo: 'testDiv'
      , config

      @waitForComponentReady @app

    getGrid: ->
      @app.gridboard?.getGridOrBoard()

    getGridColumnNames: ->
      _.map @getGrid().columns, (column) -> column.dataIndex

  beforeEach ->
    @artifactRequest = @ajax.whenQuerying('artifact').respondWith();

    @ext2AppScopedSettings =
      fetch: 'FormattedID,Name,State,Owner'
      order: 'State, Owner'
      query: '(Name contains "a")'
      url: 'Defect'

    @ext4AppScopedSettings =
      columnNames: 'Name,DefectStatus,Project,State'
      order: 'DefectStatus'
      query: '(Name !contains "b")'
      type: 'DefectSuite'

    @stub Ext.state.Manager.getProvider(), 'get', (id) =>
      if id.split('::')[1] is 'customlist-grid' then return @gridState
      if id.split('::')[1] is 'customlist-custom-filter-button' then return @filterState

  describe 'initial state', ->
    describe 'when only ext2 settings exists', ->
      beforeEach ->
        @createApp(appContainer: @ext2AppScopedSettings)

      it 'should not show the settings panel', ->
        expect(@showSettingsStub).not.toHaveBeenCalled()

      it 'should get the type from ext2 settings', ->
        expect(@app.modelNames).toEqual ['Defect']

      it 'should get the grid columns from the ext2 settings', ->
        expect(_.map @getGrid().columns, (column) -> column.dataIndex).toContainAll ['FormattedID', 'Name', 'State', 'Owner']

      it 'should get the sort order from the ext2 settings', ->
        expect(@artifactRequest.lastCall.args[0].params.order).toBe 'State ASC,Owner ASC,ObjectID'

      it 'should get the query from the ext2 settings', ->
        expect(@artifactRequest.lastCall.args[0].params.query).toBe '(Name CONTAINS "a")'

    describe 'when ext2 settings and ext4 settings exist', ->
      beforeEach ->
        @createApp(appContainer: @ext2AppScopedSettings, settings: @ext4AppScopedSettings)

      it 'should not show the settings panel', ->
        expect(@showSettingsStub).not.toHaveBeenCalled()

      it 'should get the type from ext4 settings', ->
        expect(@app.modelNames).toEqual ['DefectSuite']

      it 'should get the grid columns from the ext4 settings', ->
        expect(@getGridColumnNames()).toContainAll ['FormattedID', 'Name', 'DefectStatus', 'Project', 'State']

      it 'should get the sort order from the ext4 settings', ->
        expect(@artifactRequest.lastCall.args[0].params.order).toBe 'DefectStatus ASC,ObjectID'

      it 'should get the query from the ext4 settings', ->
        expect(@artifactRequest.lastCall.args[0].params.query).toBe '(Name !CONTAINS "b")'

    describe 'when no settings exist', ->
      beforeEach ->
        @createApp()

      it 'should show the settings panel', ->
        expect(@showSettingsStub).toHaveBeenCalledOnce()

      it 'should not create a grid', ->
        expect(@getGrid()).toBeFalsy()

    describe 'when front side filters are present', ->
      beforeEach ->
        @filterState =
          filters: [
            '(PercentDoneByStoryPlanEstimate = 1)'
            '(Name contains "yomama")'
          ]
        @createApp(settings: @ext4AppScopedSettings)

      it 'should remove invalid filters', ->
        expect(@artifactRequest.lastCall.args[0].params.query).not.toContain 'PercentDoneByStoryPlanEstimate'
        expect(_.any(@app.gridboard.down('rallycustomfilterbutton').getState().filters, (filter) -> _.contains(filter, 'PercentDoneByStoryPlanEstimate'))).toBe false

      it 'should retain valid filters', ->
        expect(@artifactRequest.lastCall.args[0].params.query).toContain '(Name CONTAINS "yomama")'
        expect(_.any(@app.gridboard.down('rallycustomfilterbutton').getState().filters, (filter) -> _.contains(filter, '(Name CONTAINS "yomama")'))).toBe true

  describe 'grid state columns', ->
    it 'should be overridden by app column settings if different', ->
      @gridState = columns: ['CreationDate', 'AcceptedDate']
      @createApp(settings: @ext4AppScopedSettings).then =>
        expect(@getGridColumnNames()).toContainAll ['FormattedID', 'Name', 'DefectStatus', 'Project', 'State']
        expect(@getGridColumnNames()).not.toContain 'CreationDate'
        expect(@getGridColumnNames()).not.toContain 'AcceptedDate'

    it 'should be retained if they contain all of the app column settings', ->
      @gridState = columns: [
        { dataIndex: 'Name' }
        { dataIndex: 'State', flex: 2 }
        { dataIndex: 'Project', flex: 3 }
        { dataIndex: 'DefectStatus', flex: 1 }
      ]
      @createApp(settings: @ext4AppScopedSettings).then =>
        statefulColumns = _(@getGrid().columns).filter((column) -> column.dataIndex ).map((column) -> _.pick(column, ['dataIndex', 'flex'])).value().splice(2)
        expect(statefulColumns).toEqual @gridState.columns

    describe 'when updated by user', ->
      beforeEach ->
        @prefUpdateStub = @stub Rally.data.PreferenceManager, 'update'

      it 'should update app scoped column settings if user has permissions to edit app settings', ->
        @createApp(settings: @ext4AppScopedSettings, owner: dashboard: arePanelSettingsEditable: true).then =>
          @getGrid().fireEvent 'beforestatesave', @getGrid(), columns: ['Name', 'Blocked', 'Iteration', 'State']
          expect(@prefUpdateStub.lastCall.args[0].settings).toEqual
            columnNames: 'Name,Blocked,Iteration,State'

      it 'should NOT update app scoped column settings if user does NOT have permissions to edit app settings', ->
        @createApp(settings: @ext4AppScopedSettings, owner: dashboard: arePanelSettingsEditable: false).then =>
          @getGrid().fireEvent 'beforestatesave', @getGrid(), columns: ['Name', 'Blocked', 'Iteration', 'State']
          expect(@prefUpdateStub).not.toHaveBeenCalled()

  describe 'add new', ->
    it 'should not show for a disallowed type', ->
      @createApp(settings: type: 'task').then =>
        expect(@app.enableAddNew).toBe false

    it 'should show for an allowed type', ->
      @createApp(settings: type: 'defect').then =>
        expect(@app.enableAddNew).toBe true

  describe 'ranking', ->
    it 'should not show for a disallowed artifact type', ->
      @createApp(settings: type: 'task').then =>
        expect(@app.enableRanking).toBe false

    it 'should show for an allowed artifact type', ->
      @createApp(settings: type: 'defect').then =>
        expect(@app.enableRanking).toBe true

  describe 'filter', ->
    helpers
      createAppWithQuery: (query) ->
        @createApp
          settings:
            type: 'userstory'
            query: query

    it 'should reload grid when timebox filter is changed', ->
      @createApp(settings: type: 'task').then =>
        loadGridBoardStub = @spy @app, 'loadGridBoard'
        Rally.environment.getMessageBus().publish(Rally.app.Message.timeboxScopeChange)
        expect(loadGridBoardStub).toHaveBeenCalledOnce()

    it 'should project scope milestones to global scope when global scope setting is on', ->
      @createApp(settings: type: 'milestone').then =>
        targetProjectFilter = _.find(@app.getPermanentFilters(), (filter)-> filter.value.property == "TargetProject" && filter.value.value == null);
        expect(targetProjectFilter).toBeDefined()

    it 'should convert {user} variable into current user ref', ->
      @createAppWithQuery('(Owner = {user})').then =>
        expect(@artifactRequest.lastCall.args[0].params.query).toBe "(Owner = \"#{Rally.environment.getContext().getUser()._ref}\")"

    it 'should convert {projectOid} variable into current project oid', ->
      @createAppWithQuery('(Project.ObjectID = {projectOid})').then =>
        expect(@artifactRequest.lastCall.args[0].params.query).toBe "(Project.ObjectID = #{Rally.environment.getContext().getProject().ObjectID})"

    it 'should convert {projectName} variable into current project name', ->
      @createAppWithQuery('(Name contains "{projectName}")').then =>
        expect(@artifactRequest.lastCall.args[0].params.query).toBe "(Name CONTAINS \"#{Rally.environment.getContext().getProject().Name}\")"

  describe 'page size', ->
    helpers
      createAppWithExt2PageSize: (pageSize) ->
        @ext2AppScopedSettings.pagesize = pageSize
        @createApp appContainer: @ext2AppScopedSettings

    it 'should default to 10 when no ext2 setting', ->
      @createAppWithExt2PageSize().then =>
        expect(@artifactRequest.lastCall.args[0].params.pagesize).toBe 10

    it 'should use the ext2 setting if is an allowed page size', ->
      @createAppWithExt2PageSize(25).then =>
        expect(@artifactRequest.lastCall.args[0].params.pagesize).toBe 25

    it 'should round up the ext2 setting to the nearest allowed page size', ->
      @createAppWithExt2PageSize(90).then =>
        expect(@artifactRequest.lastCall.args[0].params.pagesize).toBe 100

    it 'should round down the ext2 setting to 200 when greater than 200', ->
      @createAppWithExt2PageSize(201).then =>
        expect(@artifactRequest.lastCall.args[0].params.pagesize).toBe 200

  describe 'header control toolbar', ->
    it 'should be visible if showControls setting is true', ->
      @createApp(settings: { type: 'hierarchicalrequirement', showControls: true }).then =>
        expect(@app.gridboard.getHeader()).toBeVisible()

    it 'should not be visible if showControls setting is false', ->
      @createApp(settings: { type: 'hierarchicalrequirement', showControls: false }).then =>
        expect(@app.gridboard.getHeader()).not.toBeVisible()

  describe 'paging toolbar', ->
    it 'should be visible if showControls setting is true', ->
      @createApp(settings: { type: 'hierarchicalrequirement', showControls: true }).then =>
        expect(@app.gridboard.down('#pagingToolbar')).toBeVisible()

    it 'should be visible if showControls is false but more than 10 records are available', ->
      @artifactRequest = @ajax.whenQuerying('artifact').respondWith(@mom.getData 'hierarchicalrequirement', count: 25);
      @createApp(settings: { type: 'hierarchicalrequirement', showControls: false }).then =>
        expect(@app.gridboard.down('#pagingToolbar')).toBeVisible()

    it 'should not be visible if showControls is false and there are 10 or less records available', ->
      @artifactRequest = @ajax.whenQuerying('artifact').respondWith(@mom.getData 'hierarchicalrequirement', count: 10);
      @createApp(settings: { type: 'hierarchicalrequirement', showControls: false }).then =>
        expect(@app.gridboard.down('#pagingToolbar')).not.toBeVisible()
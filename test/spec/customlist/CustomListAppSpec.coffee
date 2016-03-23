Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.app.Context'
  'Rally.data.PreferenceManager'
  'Rally.data.wsapi.batch.Store'
  'Rally.ui.inlinefilter.InlineFilterPanel'
  'Rally.ui.gridboard.SharedViewComboBox'
]

describe 'Rally.apps.customlist.CustomListApp', ->
  helpers
    createApp: (config) ->
      @showSettingsStub = @stub()

      @app = Ext.create 'Rally.apps.customlist.CustomListApp', _.merge
        appContainer: {} #TODO: remove as part of F6971_REACT_DASHBOARD_PANELS
        context: Ext.create 'Rally.app.Context',
          initialValues:
            permissions: Rally.environment.getContext().getPermissions()
            project: Rally.environment.getContext().getProject()
            subscription: Rally.environment.getContext().getSubscription()
            user: Rally.environment.getContext().getUser()
            workspace: Rally.environment.getContext().getWorkspace()
        height: 500
        renderTo: 'testDiv'
        listeners:
          settingsneeded: @showSettingsStub
      , config

      @waitForComponentReady @app

    getGrid: ->
      @app.gridboard?.getGridOrBoard()

    getGridColumnNames: ->
      _.map @getGrid().columns, (column) -> column.dataIndex

    stubFeatureToggle: (toggles, value = true) ->
      stub = @stub(Rally.app.Context.prototype, 'isFeatureEnabled')
      stub.withArgs(toggle).returns(value) for toggle in toggles
      stub

  beforeEach ->
    @artifactRequest = @ajax.whenQuerying('artifact').respondWith();

    @ext2AppScopedSettings =
      fetch: 'FormattedID,Name,State,Owner'
      order: 'State, Owner'
      query: '(Name contains "a")'
      url: 'Defect'

    @ext4AppScopedSettings =
      columnNames: 'FormattedID,DragAndDropRank,Name,DefectStatus,Project,State'
      order: 'DefectStatus'
      query: '(Name !contains "b")'
      type: 'DefectSuite'

    @stub Ext.state.Manager.getProvider(), 'get', (id) =>
      if id.split('::')[1] is 'customlist-grid' then return @gridState
      if id.split('::')[1] is 'customlist-custom-filter-button' then return @filterState

  describe 'initial state', ->
    describe 'when only ext2 settings exists', ->
      beforeEach ->
        @createApp(defaultSettings: @ext2AppScopedSettings)

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

      it 'should show controls by default', ->
        expect(@app.getSetting('showControls')).toBe true

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
        { dataIndex: 'DragAndDropRank' }
        { dataIndex: 'FormattedID', flex: 2 }
        { dataIndex: 'Name' }
        { dataIndex: 'State', flex: 2 }
        { dataIndex: 'Project', flex: 3 }
        { dataIndex: 'DefectStatus', flex: 1 }
      ]
      @createApp(settings: @ext4AppScopedSettings).then =>
        statefulColumns = _(@getGrid().columns).filter((column) -> column.dataIndex).map((column) -> _.pick(column, ['dataIndex', 'flex'])).value()
        expect(statefulColumns.slice(2)).toEqual @gridState.columns.slice(2)
        expect(_(statefulColumns).take(2).pluck('dataIndex').value()).toEqual ['DragAndDropRank', 'FormattedID']

    describe 'when updated by user', ->
      beforeEach ->
        @prefUpdateStub = @stub Rally.data.PreferenceManager, 'update'

      it 'should update app scoped column settings if user has permissions to edit app settings', ->
        @createApp(settings: @ext4AppScopedSettings, isEditable: true).then =>
          @getGrid().fireEvent 'beforestatesave', @getGrid(), columns: ['Name', 'Blocked', 'Iteration', 'State']
          expect(@prefUpdateStub.lastCall.args[0].settings).toEqual
            columnNames: 'Name,Blocked,Iteration,State'

      it 'should NOT update app scoped column settings if user does NOT have permissions to edit app settings', ->
        @createApp(settings: @ext4AppScopedSettings, isEditable: false).then =>
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

  describe 'query', ->
    helpers
      createAppWithQuery: (query) ->
        @createApp
          settings:
            type: 'userstory'
            query: query

      expectBlankSlateShownWithSecondaryMessages: (secondaryMessages) ->
        expect(@app.getEl().down('.no-data-container .primary-message').getHTML()).toBe 'Invalid Query'
        expect(_.pluck(@app.getEl().query('.no-data-container .secondary-message div'), 'textContent')).toContainOnly secondaryMessages

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

    describe 'contains invalid field names', ->
      beforeEach ->
        @createAppWithQuery '(((Turd.Name = "Poopy McPoop") OR (Project.ObjectID = 123)) AND ((PoopBoolean = false) OR (TargetDate = 01/01/01)) OR (Name contains "poop"))'
      it 'should not make a request to WSAPI', ->
        expect(@artifactRequest.callCount).toBe 0

      it 'should show a blank slate with super hot detailed error messages', ->
        @expectBlankSlateShownWithSecondaryMessages [
          'Could not find the attribute "Turd" on type "User Story" in the query segment "(Turd.Name = "Poopy McPoop")"'
          'Could not find the attribute "PoopBoolean" on type "User Story" in the query segment "(PoopBoolean = false)"'
          'Could not find the attribute "TargetDate" on type "User Story" in the query segment "(TargetDate = "01/01/01")"'
        ]

    describe 'when WSAPI has "Could not parse" warnings', ->
      beforeEach ->
        @warnings = ['Could not parse "\'Submitted\'"', 'Could not parse "\'Fixed\'"']
        @ajax.whenQuerying('artifact').respondWith @mom.getData('UserStory'), warnings: @warnings
        @createAppWithQuery "((State = 'Submitted') OR (State = 'Fixed'))"

      it 'should show warnings in blank slate', ->
        @app.gridboard.getGridOrBoard().fireEvent 'storeload'

        @expectBlankSlateShownWithSecondaryMessages @warnings

      it 'should show grid has no data in paging toolbar', ->
        expect(@app.gridboard.getGridOrBoard().down('rallytreepagingtoolbar').getEl().down('.range').getHTML()).toBe '0-0'

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

  describe 'field picker', ->
    it 'should have no always selected values', ->
      @createApp(settings: { type: 'hierarchicalrequirement' }).then =>
        expect(_.find(@app.gridboard.plugins, ptype: 'rallygridboardfieldpicker').gridAlwaysSelectedValues).toEqual []

    it 'should have rank in blacklist for task', ->
      @createApp(settings: { type: 'task' }).then =>
        expect(_.find(@app.gridboard.plugins, ptype: 'rallygridboardfieldpicker').gridFieldBlackList).toContain('Rank')

    it 'should not have rank in blacklist for user story', ->
      @createApp(settings: { type: 'hierarchicalrequirement' }).then =>
        expect(_.find(@app.gridboard.plugins, ptype: 'rallygridboardfieldpicker').gridFieldBlackList).not.toContain('Rank')

  describe 'filtering panel plugin', ->
    helpers
      getPlugin: (filterptype='rallygridboardinlinefiltercontrol') ->
        gridBoard = @app.down 'rallygridboard'
        _.find gridBoard.plugins, (plugin) ->
          plugin.ptype == filterptype

    it 'should have the old filter component by default', ->
      @createApp(settings: { type: 'task' }).then =>
        expect(@getPlugin('rallygridboardcustomfiltercontrol')).toBeDefined()

    it 'should use rallygridboard filtering plugin', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp(settings: { type: 'task' }).then =>
        expect(@getPlugin()).toBeDefined()

    it 'should use appropriate artifact config', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp(settings: { type: 'task' }).then =>
        plugin = @getPlugin()
        expect(plugin.inlineFilterButtonConfig.modelNames).toBeDefined()
        expect(plugin.inlineFilterButtonConfig.inlineFilterPanelConfig.quickFilterPanelConfig.defaultFields).toEqual ['ArtifactSearch', 'Owner']
        expect(plugin.inlineFilterButtonConfig.inlineFilterPanelConfig.quickFilterPanelConfig.addQuickFilterConfig.blackListFields).toEqual ['ModelType', 'PortfolioItemType']
        expect(plugin.inlineFilterButtonConfig.inlineFilterPanelConfig.quickFilterPanelConfig.addQuickFilterConfig.whiteListFields).toEqual ['Milestones', 'Tags']

    it 'should use appropriate nonartifact config', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp(settings: { type: 'user' }).then =>
        plugin = @getPlugin()
        expect(plugin.inlineFilterButtonConfig.model).toBeDefined()
        expect(plugin.inlineFilterButtonConfig.inlineFilterPanelConfig.quickFilterPanelConfig.defaultFields).toEqual []
        expect(plugin.inlineFilterButtonConfig.inlineFilterPanelConfig.quickFilterPanelConfig.addQuickFilterConfig.blackListFields).toEqual ['ArtifactSearch', 'ModelType']
        expect(plugin.inlineFilterButtonConfig.inlineFilterPanelConfig.quickFilterPanelConfig.addQuickFilterConfig.whiteListFields).toEqual []

    it 'should use appropriate project blacklist config', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp(settings: { type: 'project' }).then =>
        plugin = @getPlugin()
        expect(plugin.inlineFilterButtonConfig.inlineFilterPanelConfig.quickFilterPanelConfig.addQuickFilterConfig.blackListFields).toEqual ['ArtifactSearch', 'ModelType', 'SchemaVersion']

    it 'should use appropriate release blacklist config', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp(settings: { type: 'release' }).then =>
        plugin = @getPlugin()
        expect(plugin.inlineFilterButtonConfig.inlineFilterPanelConfig.quickFilterPanelConfig.addQuickFilterConfig.blackListFields).toEqual ['ArtifactSearch', 'ModelType', 'ChildrenPlannedVelocity', 'Version']

    it 'should clear primary and secondary no data messages when filterchange is fired', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp(
        settings:
          type: 'project'
          query: "(foo = 'foo')"
      ).then =>
        expect(@getGrid().noDataPrimaryText).toBeDefined()
        expect(@getGrid().noDataSecondaryText).toBeDefined()
        @app.gridboard.fireEvent('filterchange', @app.gridboard)
        expect(@getGrid().noDataPrimaryText).not.toBeDefined()
        expect(@getGrid().noDataSecondaryText).not.toBeDefined()

  describe 'shared view plugin', ->
    helpers
      getPlugin: (filterptype='rallygridboardsharedviewcontrol') ->
        gridBoard = @app.down 'rallygridboard'
        _.find gridBoard.plugins, (plugin) ->
          plugin.ptype == filterptype

    beforeEach ->
      Ext.state.Manager.getProvider().get.restore();
      @stub Ext.state.Manager.getProvider(), 'get', (id) =>
        if id.split('::')[1] is 'customlist-grid' then return { columns: ['FirstName']}
        if id.split('::')[1] is 'custom-list-shared-view' then return { value: "/preference/1234" }

    it 'should not have shared view plugin if the toggle is off', ->
      @createApp(settings: { type: 'user' }).then =>
        expect(@getPlugin()).not.toBeDefined()

    it 'should use rallygridboard shared view plugin if toggled on', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp(settings: { type: 'user' }).then =>
        plugin = @getPlugin()
        expect(plugin).toBeDefined()
        expect(plugin.sharedViewConfig.stateful).toBe true
        expect(plugin.sharedViewConfig.stateId).toBe @app.getContext().getScopedStateId('custom-list-shared-view')

    it 'sets current view on viewchange', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp(settings: { type: 'user' }).then =>
        loadSpy = @spy(@app, 'loadGridBoard')
        @app.gridboard.fireEvent 'viewchange'
        expect(loadSpy).toHaveBeenCalledOnce()
        expect(@app.down('#gridBoard')).toBeDefined()

    it 'uses current view when selected', ->
      @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true
      @createApp(settings: { type: 'user' }).then =>
        expect(_.compact(@getGridColumnNames())).toEqual(['FirstName'])

  describe '#clearFiltersAndSharedViews', ->
    describe 'F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES toggled off', ->
      beforeEach ->
        @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], false

      it 'should not clear inline filter panel', ->
        @createApp(settings: { type: 'user' }).then =>
          clearSpy = @spy Rally.ui.inlinefilter.InlineFilterPanel::, 'clear'
          @app.clearFiltersAndSharedViews()
          expect(clearSpy.callCount).toBe 0

      it 'should not reset shared view combobox panel', ->
        @createApp(settings: { type: 'user' }).then =>
          resetSpy = @spy Rally.ui.gridboard.SharedViewComboBox::, 'reset'
          @app.clearFiltersAndSharedViews()
          expect(resetSpy.callCount).toBe 0

      it 'should not batch remove view records', ->
        @ajax.whenQuerying('preference').respondWith [
          Name: 'test view'
          Value: 'view stuff'
          Type: 'View'
          _ref: '/preference/0'
          AppId: '123'
        ]
        @createApp(settings: { type: 'user' }).then =>
          removeAllStub = @stub Rally.data.wsapi.batch.Store::, 'removeAll'
          @app.clearFiltersAndSharedViews()
          @once(condition: => removeAllStub.callCount == 0)

    describe 'F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES toggled on', ->
      beforeEach ->
        @stubFeatureToggle ['F8943_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_MANY_PAGES'], true

      it 'should clear inline filter panel', ->
        @createApp(settings: { type: 'user' }).then =>
          clearSpy = @spy Rally.ui.inlinefilter.InlineFilterPanel::, 'clear'
          @app.clearFiltersAndSharedViews()
          expect(clearSpy.callCount).toBe 1

      it 'should reset shared view combobox panel', ->
        @createApp(settings: { type: 'user' }).then =>
          resetSpy = @spy Rally.ui.gridboard.SharedViewComboBox::, 'reset'
          @app.clearFiltersAndSharedViews()
          expect(resetSpy.callCount).toBe 1

      it 'should batch remove view records', ->
        @ajax.whenQuerying('preference').respondWith [
          Name: 'test view'
          Value: 'view stuff'
          Type: 'View'
          _ref: '/preference/0'
          AppId: '123'
        ]
        @createApp(settings: { type: 'user' }).then =>
          removeAllStub = @stub Rally.data.wsapi.batch.Store::, 'removeAll'
          @app.clearFiltersAndSharedViews()
          @once condition: => removeAllStub.callCount > 0

Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.ui.report.StandardReport',
  'Rally.apps.kanban.KanbanApp',
  'Rally.util.Element',
  'Rally.ui.notify.Notifier',
  'Rally.app.Context',
  'Rally.test.helpers.CardBoard',
  'Rally.data.Ranker'
]

describe 'Rally.apps.kanban.KanbanApp', ->

  beforeEach ->
    @ajax.whenQuerying('artifact').respondWithCount(1, {
      values: [{
        ScheduleState: 'In-Progress'
      }]
      createImmediateSubObjects: true
    })

    @projectRef = Rally.environment.getContext().getProject()._ref
    @projectName = 'Project 1'

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'kanbanapp'

  it 'has the correct default settings', ->
    @createApp().then =>
      expect(@app.getSetting('groupByField')).toBe 'ScheduleState'
      expect(@app.getSetting('columns')).toBe Ext.JSON.encode(
        Defined:
          wip: ''
        'In-Progress':
          wip: ''
        Completed:
          wip: ''
        Accepted:
          wip: ''
      )
      expect(@app.getSetting('cardFields')).toBe 'FormattedID,Name,Owner,Discussion,Tasks,Defects'
      expect(@app.getSetting('showRows')).toBe false

  it 'should have a default card fields setting', ->
    @createApp().then =>
      expect(@cardboard.columnConfig.fields).toEqual @app.getSetting('cardFields').split(',')

  it 'should have use the cardFields setting if available', ->
    @createApp(cardFields: 'HelloKitty').then =>
      expect(@cardboard.columnConfig.fields).toEqual ['HelloKitty']

  it 'should show the field picker', ->
    @createApp().then =>
      expect(@app.down('#fieldpickerbtn').isVisible()).toBe true

  it 'does not show add new when user is not a project editor', ->
    Rally.environment.getContext().getPermissions().userPermissions[0].Role = 'Viewer'
    @createApp().then =>

      expect(@app.down 'rallyaddnew').toBeNull()

  it 'shows add new for user who is a project editor', ->
    @createApp().then =>
      expect(@app.down 'rallyaddnew').toBeDefined()

  it 'should not schedule a new item in an iteration', ->
    @createApp().then =>
      editorOpenedStub = @stub(Rally.nav.Manager, 'create')
      addNewHelper = new Helpers.AddNewHelper this, '.kanban'
      addNewHelper.addWithDetails('foo').then =>
        expect(editorOpenedStub).toHaveBeenCalledOnce()
        expect(editorOpenedStub.getCall(0).args[1].iteration).toBe 'u'

  it 'should set group by field to first column value', ->
    @createApp().then =>
      editorOpenedStub = @stub(Rally.nav.Manager, 'create')
      addNewHelper = new Helpers.AddNewHelper this, '.kanban'
      addNewHelper.addWithDetails('foo').then =>
        expect(editorOpenedStub).toHaveBeenCalledOnce()
        expect(editorOpenedStub.getCall(0).args[1][@app.getSetting('groupByField')]).toBe @cardboard.getColumns()[0].getValue()

  it 'should set custom group by field to first column value', ->
    @createApp(
      groupByField: 'KanbanState'
    ).then =>
      editorOpenedStub = @stub(Rally.nav.Manager, 'create')
      addNewHelper = new Helpers.AddNewHelper this, '.kanban'
      addNewHelper.addWithDetails('foo').then =>
        expect(editorOpenedStub).toHaveBeenCalledOnce()
        groupByField = "c_#{@app.getSetting('groupByField')}"
        expect(editorOpenedStub.getCall(0).args[1][groupByField]).toBe @cardboard.getColumns()[0].getValue()

  it 'should show correct fields on cards', ->
    @createApp(cardFields: 'Name,Defects,Project').then =>

      expect(@cardboard.columnConfig.fields).toContain 'Name'
      expect(@cardboard.columnConfig.fields).toContain 'Defects'
      expect(@cardboard.columnConfig.fields).toContain 'Project'

  it 'should show columns with correct wips based on settings', ->
    columnSettings =
      Defined:
        wip: 1
      'In-Progress':
        wip: 2

    @createApp({columns: Ext.JSON.encode(columnSettings), groupByField: 'ScheduleState'}).then =>

      columns = @cardboard.getColumns()
      expect(columns.length).toBe 2
      expect(columns[0].wipLimit).toBe columnSettings.Defined.wip
      expect(columns[1].wipLimit).toBe columnSettings['In-Progress'].wip

  it 'should show columns with correct card fields when COLUMN_LEVEL_FIELD_PICKER_ON_KANBAN_SETTINGS enabled', ->
    @stub(Rally.app.Context.prototype, 'isFeatureEnabled').withArgs('COLUMN_LEVEL_FIELD_PICKER_ON_KANBAN_SETTINGS').returns(true)
    columnSettings =
      Defined:
        cardFields: 'Name,Defects,Project'
      'In-Progress':
        cardFields: 'ScheduleState'

    @createApp({columns: Ext.JSON.encode(columnSettings)}).then =>
      columns = @cardboard.getColumns()

      expect(columns.length).toBe 2
      expect(columns[0].cardConfig.fields).toBeUndefined()
      expect(columns[0].fields).toEqual columnSettings.Defined.cardFields.split(',')
      expect(columns[1].fields).toEqual columnSettings['In-Progress'].cardFields.split(',')
      expect(columns[1].cardConfig.fields).toBeUndefined()

  it 'should show columns with cardFields when no column.cardFields settings', ->
    @stub(Rally.app.Context.prototype, 'isFeatureEnabled').withArgs('COLUMN_LEVEL_FIELD_PICKER_ON_KANBAN_SETTINGS').returns(true)
    columnSettings =
      Defined:
        wip: 1
      'In-Progress':
        wip: 2

    @createApp({cardFields: 'foobar', columns: Ext.JSON.encode(columnSettings)}).then =>
      columns = @cardboard.getColumns()

      expect(columns.length).toBe 2
      expect(columns[0].fields).toEqual ['foobar']
      expect(columns[1].fields).toEqual ['foobar']

  it 'should show columns with defaultCardFields when no cardFields or column.cardFields settings', ->
    @stub(Rally.app.Context.prototype, 'isFeatureEnabled').withArgs('COLUMN_LEVEL_FIELD_PICKER_ON_KANBAN_SETTINGS').returns(true)
    columnSettings =
      Defined:
        wip: 1
      'In-Progress':
        wip: 2
    @createApp({columns: Ext.JSON.encode(columnSettings)}).then =>
      columns = @cardboard.getColumns()

      expect(columns.length).toBe 2
      expect(columns[0].fields).toEqual @app.getSetting('cardFields').split(',')
      expect(columns[1].fields).toEqual @app.getSetting('cardFields').split(',')

  it 'should not specify any card fields to show when COLUMN_LEVEL_FIELD_PICKER_ON_KANBAN_SETTINGS is off (should let card field picker plugin control it)', ->
    @stub(Rally.app.Context.prototype, 'isFeatureEnabled').withArgs('COLUMN_LEVEL_FIELD_PICKER_ON_KANBAN_SETTINGS').returns(false)
    columnSettings =
      Defined:
        wip: 1
      'In-Progress':
        wip: 2
    @createApp({columns: Ext.JSON.encode(columnSettings)}).then =>
      columns = @cardboard.getColumns()
      expect(columns.length).toBe 2
      _.each columns, (column) =>
        expect(column.fields).toEqual @app.getSetting('cardFields').split(',')
        expect(column.cardConfig.fields).toBeUndefined()

  it 'should contain menu options', ->
    @createApp().then =>
      options = @app.getOptions()

      expect(options.length).toBe 3
      expect(options[0].text).toBe 'Show Cycle Time Report'
      expect(options[1].text).toBe 'Show Throughput Report'
      expect(options[2].text).toBe 'Print'

  it 'should correctly build report config for non schedule state field stories', ->
    @createApp().then =>
      @stub(@app, 'getSetting').returns('KanbanState')
      @stub(@app, '_getWorkItemTypesForChart').returns('G')
      report_config = @app._buildReportConfig(Rally.ui.report.StandardReport.Reports.CycleLeadTime)

      expect(report_config.filter_field).toBe @app.groupByField.displayName
      expect(report_config.work_items).toBe 'G'
      expect(report_config.report.id).toBe Rally.ui.report.StandardReport.Reports.CycleLeadTime.id

  it 'should correctly build report config for schedule state field with story and defect types', ->
    @createApp().then =>
      report_config = @app._buildReportConfig(Rally.ui.report.StandardReport.Reports.Throughput)

      expect(report_config.filter_field).toBeUndefined()
      expect(report_config.work_items).toBe 'N'
      expect(report_config.report.id).toBe Rally.ui.report.StandardReport.Reports.Throughput.id

  it 'should correctly build standard report component config', ->
    @createApp().then =>
      report_config = {report: 5}
      standard_report_config = @app._buildStandardReportConfig(report_config)

      expect(standard_report_config.project).toBe @app.getContext().getDataContext().project
      expect(standard_report_config.projectScopeDown).toBe @app.getContext().getDataContext().projectScopeDown
      expect(standard_report_config.projectScopeUp).toBe @app.getContext().getDataContext().projectScopeUp
      expect(standard_report_config.reportConfig).toBe report_config

  it 'should exclude items with a release set in the last column', ->
    @createApp(hideReleasedCards: true).then =>
      columns = @cardboard.getColumns()
      _.each columns, (column, index) ->
        expect(column.hideReleasedCards).toBe index == columns.length - 1

  it 'should not exclude items with a release set in the last column', ->
    @createApp(hideReleasedCards: false).then =>
      _.each @cardboard.getColumns(), (column) ->
        expect(column.hideReleasedCards).toBe false

  it 'should show plan estimate when plan estimate field is enabled', ->
    @createApp(cardFields: "Name,Discussion,Tasks,Defects,PlanEstimate").then =>
      expect(@app.getEl().down('.PlanEstimate')).not.toBeNull()

  it 'should not show plan estimate when plan estimate field is disabled', ->
    @createApp(cardFields: "Name,Discussion,Tasks,Defects").then =>
      expect(@app.getEl().down('.rui-card-content')).toBeDefined()
      expect(@app.getEl().down('.PlanEstimate')).toBeNull()

  it 'should specify the correct policy preference setting key', ->
    policy = 'Foo'
    settingsKey = 'ScheduleStateDefinedPolicy'
    settings = {}
    settings[settingsKey] = policy
    @createApp(settings).then =>
      @assertPolicyCmpConfig(settingsKey, policy)

  it 'should load legacy non field scoped policy setting', ->
    policy = 'Foo'
    settingsKey = 'ScheduleStateDefinedPolicy'
    settings = {}
    settings['DefinedPolicy'] = policy
    @createApp(settings).then =>
      @assertPolicyCmpConfig(settingsKey, policy)

  it 'should load policy setting when column has WSAPI 2.x c_ prefix', ->
    policy = 'Foo'
    groupByRoot = 'SomeCustomField'
    groupByField = 'c_' + groupByRoot
    settingsKey = groupByRoot + "DefinedPolicy"
    settings = {}
    settings.groupByField = groupByField
    settings[settingsKey] = policy

    field =
      name: groupByField

    try
      userstory_model = Rally.test.mock.data.WsapiModelFactory.getUserStoryModel()
      userstory_model.addField field
      defect_model = Rally.test.mock.data.WsapiModelFactory.getDefectModel()
      defect_model.addField field
    finally
      @removeField(userstory_model, field)
      @removeField(defect_model, field)

    @createApp(settings).then =>
      @assertPolicyCmpConfig('c_' + settingsKey, policy)

  it 'should be able to scroll forwards', ->
    @createApp({},
      renderTo: Rally.test.helpers.CardBoard.smallContainerForScrolling()
    ).then =>
      Rally.test.helpers.CardBoard.scrollForwards @cardboard, @

  it 'should be able to scroll backwards', ->
    @createApp({},
      renderTo: Rally.test.helpers.CardBoard.smallContainerForScrolling()
    ).then =>
      Rally.test.helpers.CardBoard.scrollBackwards @cardboard, @

  it 'should have correct icons on cards', ->
    @createApp().then =>
      expect(@app.getEl().query('.rally-card-icon').length).toBe 5
      expect(@app.getEl().query('.card-gear-icon').length).toBe 1
      expect(@app.getEl().query('.card-plus-icon').length).toBe 1
      expect(@app.getEl().query('.card-ready-icon').length).toBe 1
      expect(@app.getEl().query('.card-blocked-icon').length).toBe 1
      expect(@app.getEl().query('.card-color-icon').length).toBe 1

  it 'should include the query filter from settings', ->
    query = '(Name = "foo")'
    @createApp(query: query).then =>
      storeConfig = @app.down('rallygridboard').storeConfig
      expect(storeConfig.filters.length).toBe 1
      expect(storeConfig.filters[0].toString()).toBe query

  it 'should include the filter from timebox scope', ->
    iteration = @mom.getRecord 'iteration'
    timeboxScope = Ext.create 'Rally.app.TimeboxScope', record: iteration
    @createApp({}, {}, timebox: timeboxScope).then =>
      storeConfig = @app.down('rallygridboard').storeConfig
      expect(storeConfig.filters.length).toBe 1
      expect(storeConfig.filters[0].toString()).toBe timeboxScope.getQueryFilter().toString()

  it 'should include the filters from timebox scope and settings', ->
    iteration = @mom.getRecord 'iteration'
    timeboxScope = Ext.create 'Rally.app.TimeboxScope', record: iteration
    query = '(Name = "foo")'
    @createApp(query: query, {}, timebox: timeboxScope).then =>
      storeConfig = @app.down('rallygridboard').storeConfig
      expect(storeConfig.filters.length).toBe 2
      expect(storeConfig.filters[0].toString()).toBe query
      expect(storeConfig.filters[1].toString()).toBe timeboxScope.getQueryFilter().toString()

  describe 'Swim Lanes', ->
    it 'should include rows configuration with rowsField when showRows setting is true', ->
      @createApp(showRows: true, rowsField: 'Owner').then =>
        expect(@cardboard.rowConfig.field).toBe 'Owner'
        expect(@cardboard.rowConfig.sortDirection).toBe 'ASC'

    it 'should not include rows configuration when showRows setting is false', ->
      @createApp(showRows: false, rowsField: 'Owner').then =>
        expect(@cardboard.rowConfig).toBeNull()

  describe 'Fixed Header', ->
    it 'should add the fixed header plugin', ->
      @createApp().then =>
        expect(@getPlugin('rallyfixedheadercardboard', @cardboard)).toBeDefined()

    it 'should set the initial gridboard height to the app height', ->
      @createApp().then =>
        expect(@app.down('rallygridboard').getHeight()).toBe @app.getHeight()

  describe 'plugins', ->

    describe 'filtering', ->
      it 'should use rallygridboard custom filter control', ->
        @createApp().then =>
          plugin = @getPlugin('rallygridboardcustomfiltercontrol')
          expect(plugin).toBeDefined()
          expect(plugin.filterChildren).toBe true
          expect(plugin.filterControlConfig.stateful).toBe true
          expect(plugin.filterControlConfig.stateId).toBe @app.getContext().getScopedStateId('kanban-custom-filter-button')
          expect(plugin.filterControlConfig.modelNames).toEqual ['User Story', 'Defect']

          expect(plugin.showOwnerFilter).toBe true
          expect(plugin.ownerFilterControlConfig.stateful).toBe true
          expect(plugin.ownerFilterControlConfig.stateId).toBe @app.getContext().getScopedStateId('kanban-owner-filter')

    describe 'field picker', ->
      it 'should use rallygridboard field picker', ->
        @createApp().then =>
          plugin = @getPlugin('rallygridboardfieldpicker')
          expect(plugin).toBeDefined()
          expect(plugin.headerPosition).toBe 'left'
          expect(plugin.modelNames).toEqual ['User Story', 'Defect']
          expect(@cardboard.columnConfig.fields).toEqual @app.getSetting('cardFields').split(',')

  helpers
    createApp: (settings = {}, options = {}, context = {}) ->
      @app = Ext.create 'Rally.apps.kanban.KanbanApp',
        context: Ext.create('Rally.app.Context',
          initialValues:
            Ext.merge({
              project:
                _ref: @projectRef
                Name: @projectName
              workspace:
                WorkspaceConfiguration:
                  DragDropRankingEnabled: if Ext.isDefined(options.DragDropRankingEnabled) then options.DragDropRankingEnabled else true},
              context)
        )
        settings: settings
        renderTo: options.renderTo || 'testDiv'
        height: 400

      @waitForComponentReady(@app).then =>
        @cardboard = @app.down('rallycardboard')
        @cardboard.hideMask()

    assertPolicyCmpConfig: (settingsKey, policy) ->
      column = @cardboard.getColumns()[0]
      plugin = _.find(column.plugins, {ptype: 'rallycolumnpolicy'});
      prefConfigSettings = plugin.policyCmpConfig.prefConfig.settings
      expect(Ext.Object.getKeys(prefConfigSettings)[0]).toBe settingsKey
      expect(prefConfigSettings[settingsKey]).toBe policy
      expect(plugin.policyCmpConfig.policies).toBe policy

    removeField: (model, field) ->
      model.prototype.fields.remove field
      expect(model.getField(field.name)).toBeUndefined

    getPlugin: (xtype, cmp = @app.down('rallygridboard')) ->
      _.find cmp.plugins, (plugin) ->
        plugin.ptype == xtype

Ext = window.Ext4 || window.Ext

describe 'Rally.apps.milestones.MilestonesApp', ->
  helpers
    _getContext: (canEdit = true) ->
      globalContext = Rally.environment.getContext()
      workspace = globalContext.getWorkspace()
      workspace.Name = 'default workspace'

      globalContext.getPermissions().isProjectEditor = -> canEdit
      globalContext.getPermissions().isWorkspaceOrSubscriptionAdmin = -> canEdit

      context = Ext.create 'Rally.app.Context',
        initialValues:
          project: globalContext.getProject()
          workspace: globalContext.getWorkspace()
          user: globalContext.getUser()
          subscription: globalContext.getSubscription()

      context

    _createApp: (@milestoneData, canEdit = true) ->
      @ajax.whenQuerying('project').respondWith [_ref: '/project/123']
      @ajax.whenQuerying('typedefinition').respondWith [Rally.test.mock.data.WsapiModelFactory.getModelDefinition('Milestone')]
      @ajax.whenQuerying('Milestone').respondWith @milestoneData, delay: true

      @app = Ext.create 'Rally.apps.milestones.MilestonesApp',
        getHeight: -> 500
        context: @_getContext canEdit
        renderTo: 'testDiv'

      @waitForComponentReady @app.gridboard

    _createAppWithData: (values = {}) ->
      @_createApp @mom.getData 'Milestone', values: values

    _createAppWithNoData: (canEdit = true) ->
      @_createApp [], canEdit

  afterEach ->
    @app?.destroy()

  describe 'when application is rendered', ->
    it 'should display data in the grid', ->
      @_createAppWithData(TargetDate: new Date, DisplayColor: '#FF0000').then =>
        expect(@app.getEl().down('.formatted-id-template').getHTML()).toContain @milestoneData[0].FormattedID
        expect(@app.getEl().down('.name').getHTML()).toContain @milestoneData[0].Name
        expect(@app.getEl().down('.displaycolor').getHTML()).toContain @milestoneData[0].DisplayColor
        expect(@app.getEl().down('.targetdate').getHTML()).toContain @milestoneData[0].TargetDate.getFullYear()
        expect(@app.getEl().down('.totalartifactcount').getHTML()).toContain @milestoneData[0].TotalArtifactCount

    it 'should display some canned text if the grid is empty', ->
      @_createAppWithNoData().then =>
        expect(@app.getEl().down('.no-data-container').getHTML()).toContain 'Based on your selections, no milestones were found'

  describe 'project column text', ->
    it 'should indicate project scoping', ->
      @_createAppWithData(
        TargetProject:
          Name: 'Test Project 2'
      ).then =>
        expect(@app.getEl().down('.targetproject').getHTML()).toContain @milestoneData[0].TargetProject.Name

    it 'should indicate workspace scoping', ->
      @_createAppWithData(
        TargetProject: null
      ).then =>
        expect(@app.getEl().down('.targetproject').getHTML()).toContain 'All projects in default workspace'

    it 'should indicate insufficient permissions for target project', ->
      @_createAppWithData(
        TargetProject: ''
      ).then =>
        expect(@app.getEl().down('.targetproject').getHTML()).toContain 'Project Permissions Required'

  describe 'add new', ->
    describe 'fields', ->
      beforeEach ->
        @_createAppWithData().then =>
          @addNew = @app.down 'rallyaddnew'

      it 'includes a field for target date', ->
        targetDateField = @addNew.additionalFields[0]
        expect(targetDateField.xtype).toBe 'rallydatefield'
        expect(targetDateField.emptyText).toBe 'Select Date'
        expect(targetDateField.name).toBe 'TargetDate'

      it 'includes a field for target project', ->
        targetDateField = @addNew.additionalFields[1]
        expect(targetDateField.xtype).toBe 'rallymilestoneprojectcombobox'
        expect(targetDateField.name).toBe 'TargetProject'
        expect(targetDateField.value).toBe @app.getContext().getProjectRef()

  describe 'row actions', ->
    helpers
      createAppAndClickGear: (isAdmin) ->
        @_createAppWithData(TargetProject: null, _p: 2 + 5 * isAdmin).then =>
          @click(css: ".row-action-icon").then ->
            Ext.query('.rally-menu .' + Ext.baseCSSPrefix + 'menu-item-link')

    it 'should have only a delete option when can edit target project', ->
      @createAppAndClickGear(true).then (menuItems) ->
        expect(menuItems.length).toBe 1
        expect(menuItems[0].textContent).toBe 'Delete'

    it 'should not have any options when cannot edit target project', ->
      @createAppAndClickGear(false).then (menuItems) ->
        expect(menuItems.length).toBe 0

  describe 'store config', ->
    it 'should have project scoping filters', ->
      @_createAppWithNoData().then =>
        expect(@app.gridboard.gridConfig.storeConfig.filters[0].config.value.property).toBe 'TargetProject'
        expect(@app.gridboard.gridConfig.storeConfig.filters[0].property.property).toBe 'Projects'

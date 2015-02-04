Ext = window.Ext4 || window.Ext

describe 'Rally.apps.milestones.MilestonesApp', ->
  helpers
    createApp: (@milestoneData, canEdit = true) ->
      @ajax.whenQuerying('project').respondWith [_ref: '/project/123']
      @ajax.whenQuerying('typedefinition').respondWith [@modelFactory.getModelDefinition('Milestone')]
      @ajax.whenQuerying('Milestone').respondWith @milestoneData, delay: true

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

      @app = Ext.create 'Rally.apps.milestones.MilestonesApp',
        getHeight: -> 500
        context: context
        renderTo: 'testDiv'

      @waitForComponentReady @app.gridboard

    createAppWithData: (values = {}) ->
      @createApp @mom.getData 'Milestone', values: values

    createAppWithNoData: (canEdit = true) ->
      @createApp [], canEdit
      
    getFirstDataRow: ->
      @app.getEl().down '.btid-row-' + @milestoneData[0].ObjectID

  afterEach ->
    @app?.destroy()

  describe 'when application is rendered', ->
    it 'should display data in the grid', ->
      @createAppWithData(TargetDate: new Date, DisplayColor: '#FF0000').then =>
        expect(@getFirstDataRow().down('.formatted-id-template').getHTML()).toContain @milestoneData[0].FormattedID
        expect(@getFirstDataRow().down('.name').getHTML()).toContain @milestoneData[0].Name
        expect(@getFirstDataRow().down('.displaycolor').getHTML()).toContain @milestoneData[0].DisplayColor
        expect(@getFirstDataRow().down('.targetdate').getHTML()).toContain @milestoneData[0].TargetDate.getFullYear()
        expect(@getFirstDataRow().down('.totalartifactcount').getHTML()).toContain @milestoneData[0].TotalArtifactCount

    it 'should display some canned text if the grid is empty', ->
      @createAppWithNoData().then =>
        expect(@app.getEl().down('.no-data-container').getHTML()).toContain 'Based on your selections, no milestones were found'

    it 'should render a filter button', ->
      @createAppWithData().then =>
        filterButton = @app.down 'rallycustomfilterbutton'
        expect(filterButton).toBeVisible()
        expect(filterButton.stateId).toBe @app.getContext().getScopedStateId('milestone-custom-filter-button')

  describe 'project column text', ->
    it 'should indicate project scoping', ->
      @createAppWithData(TargetProject: Name: 'Test Project 2').then =>
        expect(@getFirstDataRow().down('.targetproject').getHTML()).toContain @milestoneData[0].TargetProject.Name

    it 'should indicate workspace scoping', ->
      @createAppWithData(TargetProject: null).then =>
        expect(@getFirstDataRow().down('.targetproject').getHTML()).toContain 'All projects in default workspace'

    it 'should indicate insufficient permissions for target project', ->
      @createAppWithData(TargetProject: '').then =>
        expect(@getFirstDataRow().down('.targetproject').getHTML()).toContain 'Project Permissions Required'

  describe 'add new', ->
    describe 'fields', ->
      beforeEach ->
        @createAppWithData().then =>
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
        @createAppWithData(TargetProject: null, _p: 2 + 5 * isAdmin).then =>
          @click(css: ".btid-row-#{@milestoneData[0].ObjectID} .row-action-icon").then ->
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
      @createAppWithNoData().then =>
        expect(@app.gridboard.gridConfig.storeConfig.filters[0].config.value.property).toBe 'TargetProject'
        expect(@app.gridboard.gridConfig.storeConfig.filters[0].property.property).toBe 'Projects'

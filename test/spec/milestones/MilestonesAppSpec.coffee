Ext = window.Ext4 || window.Ext

describe 'Rally.apps.milestones.MilestonesApp', ->
  helpers
    _getContext: (canEdit = true) ->
      globalContext = Rally.environment.getContext()

      context = Ext.create 'Rally.app.Context',
        project:globalContext.getProject()
        workspace:globalContext.getWorkspace()
        user:globalContext.getUser()
        subscription:globalContext.getSubscription()

      context.getPermissions = ->
        isProjectEditor: ->
          canEdit

      context

    _createApp: (milestoneData, canEdit = true) ->
      @ajax.whenQuerying('typedefinition').respondWith [Rally.test.mock.data.WsapiModelFactory.getModelDefinition('Milestone')]
      @milestoneData = milestoneData
      milestoneQuery = @ajax.whenQuerying('milestone').respondWith @milestoneData

      @app = Ext.create 'Rally.apps.milestones.MilestonesApp',
        context: @_getContext canEdit
        renderTo: 'testDiv'

      @waitForCallback milestoneQuery

    _createAppWithData: ->
      @_createApp [
        {
          FormattedID: 'MI6'
          Name: 'Milestones are awesome',
          TargetDate: new Date()
        }
      ]

    _createAppWithNoData: (canEdit = true) ->
      @_createApp [], canEdit

  afterEach ->
    @app?.destroy()

  describe 'when application is rendered', ->

    it 'should have a button to add new if allowed to edit', ->
      @_createAppWithNoData(true).then =>
        expect(@app.getEl().down('#addNewContainer .x-btn-inner').getHTML()).toBe '+ Add New'

    it 'should not have a button to add new if not allowed to edit', ->
      @_createAppWithNoData(false).then =>
        expect(@app.getEl().down('#addNewContainer .x-btn-inner')).toBeNull()

    it 'should display data in the grid', ->
      @_createAppWithData().then =>
        expect(@app.getEl().down('.formatted-id-template').getHTML()).toContain @milestoneData[0].FormattedID
        expect(@app.getEl().down('.name').getHTML()).toContain @milestoneData[0].Name
        expect(@app.getEl().down('.targetdate').getHTML()).toContain @milestoneData[0].TargetDate.getFullYear()

    it 'should display some canned text if the grid is empty', ->
      @_createAppWithNoData().then =>
        expect(@app.getEl().down('.no-data-container').getHTML()).toContain 'Looks like milestones have not yet been defined for the current project'
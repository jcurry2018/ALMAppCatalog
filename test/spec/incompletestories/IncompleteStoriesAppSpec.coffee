Ext = window.Ext4 || window.Ext

describe 'Rally.apps.incompletestories.IncompleteStoriesApp', ->
  helpers
    createApp: (config) ->
      @app = Ext.create 'Rally.apps.incompletestories.IncompleteStoriesApp', _.merge
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
        settings:
          columnNames: 'FormattedID,DragAndDropRank,Name,DefectStatus,Project,State'
          order: 'DefectStatus'
          query: '(Name !contains "b")'
          type: 'DefectSuite'
      , config

      @waitForComponentReady @app

  beforeEach ->
    @artifactRequest = @ajax.whenQuerying('artifact').respondWith();

  describe '#getAddNewConfig', ->

    it 'should disable the add new button', ->
      @createApp()
      expect(@app.down('rallyaddnew').disableAddButton).toBe true
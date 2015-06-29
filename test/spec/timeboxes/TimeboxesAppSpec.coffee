Ext = window.Ext4 || window.Ext

Ext.require 'Rally.data.PreferenceManager'

describe 'Rally.apps.timeboxes.TimeboxesApp', ->
  helpers
    createApp: (selectedType = 'iteration', config = {}) ->
      config = _.merge(
        context: Ext.create 'Rally.app.Context',
          initialValues:
            permissions: Rally.environment.getContext().getPermissions()
            project: Rally.environment.getContext().getProject()
            subscription: Rally.environment.getContext().getSubscription()
            user: Rally.environment.getContext().getUser()
            workspace: Rally.environment.getContext().getWorkspace()
        height: 500
        renderTo: 'testDiv'
      , config)

      @ajax.whenQueryingEndpoint('/charts/iterationVelocityChart.sp').respondWithString Ext.JSON.encode('<div><input/></div>')

      @requestStubs = _.reduce ['milestone', 'iteration', 'release'], (result, type) =>
        result[type] = @ajax.whenQuerying(type).respondWith @mom.getData type
        result
      , {}

      @preferenceLoadStub = @stub Rally.data.PreferenceManager, 'load', (options) ->
        options.success.call options.scope, 'timebox-combobox': selectedType if options.filterByName is 'timebox-combobox'

      @app = Ext.create 'Rally.apps.timeboxes.TimeboxesApp', config
      @waitForComponentReady @app

    getChartButton: ->
      @app.gridboard.getHeader().down '#chart'

    getHeader: ->
      @app.gridboard.getHeader()

    createStoreStub: ->
      storeStub =
        getUpdatedRecords: -> ['test']
        suspendEvents: @stub()
        load: @stub()
        resumeEvents: @stub()

  describe 'milestones', ->
    beforeEach ->
      @createApp 'milestone'

    it 'should have the correct App ID', ->
      expect(@app.getAppId()).toBe -200004

    it 'should filter by current project', ->
      expect(@requestStubs.milestone.lastCall.args[0].params.query).toBe "((Projects contains \"#{@app.getContext().getProjectRef()}\") OR (TargetProject = null))"

    it 'should have a disabled chart button', ->
      expect(@getChartButton().disabled).toBe true

    it 'should not have an xml export button', ->
      expect(@app.xmlExportEnabled()).toBe false

  describe 'iterations', ->
    beforeEach ->
      @createApp 'iteration'

    it 'should have the correct App ID', ->
      expect(@app.getAppId()).toBe -200013

    it 'should not add a query filter', ->
      expect(@requestStubs.iteration.lastCall.args[0].params.query).toBeEmpty()

    it 'should have a disabled chart button', ->
      expect(@getChartButton().disabled).toBe false

    it 'should have an xml export button', ->
      expect(@app.xmlExportEnabled()).toBe true

    it 'should allow editing of the Name field', ->
      expect(_.find(@app.gridboard.getGridOrBoard().columns, (column) -> column.dataIndex =='Name').tdCls).toContain 'editable'

  describe 'releases', ->
    beforeEach ->
      @createApp 'release'

    it 'should have the correct App ID', ->
      expect(@app.getAppId()).toBe -200012

    it 'should not add a query filter', ->
      expect(@requestStubs.release.lastCall.args[0].params.query).toBeEmpty()

    it 'should have a disabled chart button', ->
      expect(@getChartButton().disabled).toBe true

    it 'should have an xml export button', ->
      expect(@app.xmlExportEnabled()).toBe true

    it 'should allow editing of the Name field', ->
      expect(_.find(@app.gridboard.getGridOrBoard().columns, (column) -> column.dataIndex =='Name').tdCls).toContain 'editable'

  describe 'on type change', ->
    beforeEach ->
      @createApp('iteration').then =>
        expect(@requestStubs.iteration).toHaveBeenCalledOnce()
        expect(@requestStubs.release).not.toHaveBeenCalled()
        @requestStubs.iteration.reset()
        delete @app.componentReady
        @app.modelPicker.setValue 'release'
        @waitForComponentReady @app

    it 'make a request for the new type', ->
      expect(@requestStubs.iteration).not.toHaveBeenCalled()
      expect(@requestStubs.release).toHaveBeenCalledOnce()

  describe 'gridboard store data changed', ->
    it 're-loads the store when a record is added for iterations', ->
      @createApp 'iteration'
      storeStub = @createStoreStub()
      @waitForComponentReady(@app.gridboard).then =>
        @app.gridboard.getGridOrBoard().fireEvent('storedatachanged', storeStub)

        expect(storeStub.suspendEvents).toHaveBeenCalledOnce()
        expect(storeStub.load).toHaveBeenCalledOnce()
        expect(storeStub.resumeEvents).toHaveBeenCalledOnce()

    it 're-loads the store when a record is added for releases', ->
      @createApp 'release'
      storeStub = @createStoreStub()
      @waitForComponentReady(@app.gridboard).then =>
        @app.gridboard.getGridOrBoard().fireEvent('storedatachanged', storeStub)

        expect(storeStub.suspendEvents).toHaveBeenCalledOnce()
        expect(storeStub.load).toHaveBeenCalledOnce()
        expect(storeStub.resumeEvents).toHaveBeenCalledOnce()

    it 'does not re-load the store when a record is added for milestones', ->
      @createApp 'milestone'
      storeStub = @createStoreStub()
      @waitForComponentReady(@app.gridboard).then =>
        @app.gridboard.getGridOrBoard().fireEvent('storedatachanged', storeStub)

        expect(storeStub.suspendEvents).not.toHaveBeenCalled()
        expect(storeStub.load).not.toHaveBeenCalled()
        expect(storeStub.resumeEvents).not.toHaveBeenCalled()

  describe 'in chart mode', ->
    beforeEach ->
      @createApp 'iteration', toggleState: 'chart'

    it 'should disable non-applicable header controls', ->
      expect(@getHeader().down('rallyaddnew').disabled).toBe true
      expect(@getHeader().down('rallycustomfilterbutton').disabled).toBe true
      expect(@getHeader().down('#fieldpickerbtn').disabled).toBe true
      expect(@getHeader().down('#actions-menu-button').disabled).toBe true

    it 'should not disable applicable header controls', ->
      expect(@getHeader().down('#grid').disabled).toBe false
      expect(@getHeader().down('#chart').disabled).toBe false

Ext = window.Ext4 || window.Ext

describe 'Rally.apps.releaseplanning.ReleasePlanningApp', ->
  helpers
    getTimeboxColumns: ->
      @app.gridboard.getGridOrBoard().getColumns().slice(1)

    getColumn: (index) ->
      @app.gridboard.getGridOrBoard().getColumns()[index]

    getProgressBarHtml: (columnIndex) ->
      @getColumn(columnIndex).getProgressBar().getEl().select('.progress-bar-label').item(0).getHTML()
      
  beforeEach ->
    @ajax.whenQuerying('typedefinition').respondWith [Rally.test.mock.data.WsapiModelFactory.getModelDefinition('PortfolioItemFeature')]

    @releaseData = Helpers.TimeboxDataCreatorHelper.createTimeboxData
      timeboxCount: 4
      type: 'release'
      plannedVelocity: 20

    # return the releases out of order. sorting should be done correctly on the client
    @releaseData[1] = @releaseData[3];
    @releaseData = @releaseData.slice(0,3);
    @ajax.whenQuerying('release').respondWith @releaseData

    @featureData = @mom.getData 'portfolioitem/feature',
      values:
        Release:
          _ref: @releaseData[0]._ref
        PreliminaryEstimate:
          Value: 12

    @ajax.whenQuerying('portfolioitem/feature').respondWith @featureData

    @app = Ext.create 'Rally.apps.releaseplanning.ReleasePlanningApp',
      context: Ext.create 'Rally.app.Context',
        initialValues:
          project:
            _ref: @releaseData[0].Project._ref
          subscription: Rally.environment.getContext().getSubscription()
          workspace: Rally.environment.getContext().getWorkspace()
      renderTo: 'testDiv'

    @waitForComponentReady @app

  afterEach ->
    @app.destroy()

  it 'should show a feature card in the correct release column', ->
    expect(@getColumn(1).getCards()[0].getRecord().get('Name')).toBe @featureData[0].Name

  it 'should show a progress bar based on preliminary estimate and planned velocity', ->
    expect(@getProgressBarHtml(1)).toStartWith '12'
    expect(@getProgressBarHtml(1)).toContain '20'

  it 'should order the release columns based on end date', ->
    sortedReleaseNames = _.pluck _.sortBy(@releaseData, (release) -> new Date(release.ReleaseDate)), 'Name'
    expect(_.map(@getTimeboxColumns(), (column) -> column.getTimeboxRecords()[0].get('Name'))).toEqual sortedReleaseNames

  it 'should use rallygridboard custom filter control', ->
    gridBoard = @app.down 'rallygridboard'
    plugin = _.find gridBoard.plugins, (plugin) ->
      plugin.ptype == 'rallygridboardcustomfiltercontrol'
    expect(plugin).toBeDefined()
    expect(plugin.filterControlConfig.stateful).toBe true
    expect(plugin.filterControlConfig.stateId).toBe @app.getContext().getScopedStateId('release-planning-custom-filter-button')

    expect(plugin.showOwnerFilter).toBe true
    expect(plugin.ownerFilterControlConfig.stateful).toBe true
    expect(plugin.ownerFilterControlConfig.stateId).toBe @app.getContext().getScopedStateId('release-planning-owner-filter')


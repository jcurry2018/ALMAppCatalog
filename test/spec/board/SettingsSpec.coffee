Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.board.Settings',
]

describe 'Rally.apps.board.Settings', ->

  beforeEach ->
    @ajax.whenQuerying('TypeDefinition').respondWithCount(3, {
      values: [
        {
          DisplayName: 'User Story'
          ElementName: 'HierarchicalRequirement'
          TypePath: 'HierarchicalRequirement'
          Parent:
            ElementName: 'Requirement'
        }
        {
          DisplayName: 'Defect'
          ElementName: 'Defect'
          TypePath: 'Defect'
          Parent:
            ElementName: 'SchedulableArtifact'
        }
        {
          DisplayName: 'Portfolio Item Project'
          ElementName: 'Project'
          TypePath: 'PortfolioItem/Project'
          Parent:
            ElementName: 'PortfolioItem'
        }
        {
          DisplayName: 'Attachment'
          ElementName: 'Attachment'
          TypePath: 'Attachment'
          Parent:
            ElementName: 'WorkspaceDomainObject'
        }
      ]
    })

  afterEach ->
    @container?.destroy()

  it 'displays the type combobox correctly', ->
    @createSettings().then =>
      typeCombo = @_getTypeCombo()
      types = Ext.Array.map(typeCombo.getStore().getRange(), (record) ->
        record.get(typeCombo.getDisplayField()))

      expect(types.length).toBe 3 #attachment excluded b/c no formatted id

      #sorted by display name
      expect(types[0]).toBe 'Defect'
      expect(types[1]).toBe 'Portfolio Item Project'
      expect(types[2]).toBe 'User Story'

  it 'passes the context to the type combobox correctly', ->
    @createSettings().then =>
      typeCombo = @_getTypeCombo()

      expect(typeCombo.context).toEqual @container.getContext()

  it 'refreshes the type combo box when the context changes', ->
    newContext = @_getContext
      project:
        _ref: '/project/2'
        Name: 'Project 2'

    @createSettings().then =>
      refreshSpy = @spy @_getTypeCombo(), 'refreshWithNewContext'
      @container.fireEvent 'projectscopechanged', newContext

      expect(refreshSpy).toHaveBeenCalledOnce()
      expect(refreshSpy.getCall(0).args[0]).toBe newContext

  it 'refreshes the group by combo when the type changes', ->
    @createSettings(type: 'Defect').then =>
      groupByRefreshSpy = @spy(@_getGroupByCombo(), 'refreshWithNewModelType')
      typeCombo = @_getTypeCombo()
      newValue = 'HierarchicalRequirement'
      typeCombo.fireEvent('select', typeCombo, [typeCombo.findRecordByValue(newValue)])

      expect(groupByRefreshSpy).toHaveBeenCalledOnce()
      expect(groupByRefreshSpy.getCall(0).args[0]).toBe newValue
      expect(groupByRefreshSpy.getCall(0).args[1]).toBe typeCombo.context

  it 'displays only writable fields with allowed values in group by combo', ->
    @createSettings().then =>
      Ext.Array.each(@_getGroupByCombo().getStore().getRange(), (record) ->
        attr = record.get('fieldDefinition').attributeDefinition
        expect(attr && !attr.ReadOnly && attr.Constrained && attr.AttributeType != 'COLLECTION').toBe true
      )

  it 'refreshes the swimlanes setting when the type changes', ->
    @createSettings(type: 'Defect').then =>
      swimLanesRefreshSpy = @spy(@_getSwimLanes(), 'refreshWithNewModelType')
      typeCombo = @_getTypeCombo()
      newValue = 'HierarchicalRequirement'
      typeCombo.fireEvent('select', typeCombo, [typeCombo.findRecordByValue(newValue)])

      expect(swimLanesRefreshSpy).toHaveBeenCalledOnce()
      expect(swimLanesRefreshSpy.getCall(0).args[0]).toBe newValue

  it 'includes the correct swimlane fields', ->
    @createSettings().then =>
      swimLanes = @_getSwimLanes()
      expect(swimLanes.includeCustomFields).toBe true
      expect(swimLanes.includeConstrainedNonCustomFields).toBe true
      expect(swimLanes.includeConstrainedNonCustomFields).toBe true
  helpers
    createSettings: (settings={}, contextValues)->
      settingsReady = @stub()
      context = @_getContext(contextValues)
      @container = Ext.create('Rally.app.AppSettings', {
        renderTo: 'testDiv',
        context: context,
        settings: settings,
        fields: Rally.apps.board.Settings.getFields(context),
        listeners: {
          appsettingsready: settingsReady
        }
      })

      @once(condition: -> settingsReady.called)

    _getContext: (context) ->
      Ext.create('Rally.app.Context',
        initialValues: Ext.apply(
          project:
            _ref: '/project/1'
            Name: 'Project 1'
          workspace:
            WorkspaceConfiguration:
              DragDropRankingEnabled: true
        , context)
      )

    _getFieldAt: (index) ->
      @container.down('form').form.getFields().getAt(index)

    _getTypeCombo: ->
      @_getFieldAt(0)

    _getGroupByCombo: ->
      @_getFieldAt(1)

    _getSwimLanes: ->
      @_getFieldAt(2)

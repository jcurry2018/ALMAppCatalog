Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.board.Settings',
]

describe 'Rally.apps.board.Settings', ->
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

    _getOrder: ->
      @_getFieldAt(5)

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

  it 'excludes these special fields', ->
    @createSettings(type: 'HierarchicalRequirement').then =>
      Ext.Array.each(@_getGroupByCombo().getStore().getRange(), (record) ->
        attr = record.get('fieldDefinition').attributeDefinition
        expect(attr.Name).not.toBe 'Iteration'
        expect(attr.Name).not.toBe 'Release'
        expect(attr.Name).not.toBe 'Project'
      )

  it 'excludes user object fields', ->
    @createSettings(type: 'HierarchicalRequirement').then =>
      Ext.Array.each(@_getGroupByCombo().getStore().getRange(), (record) ->
        attr = record.get('fieldDefinition').attributeDefinition
        expect(attr.Name != 'Owner').toBe true
      )

  it 'refreshes the swimlanes setting when the type changes', ->
    @createSettings(type: 'Defect').then =>
      swimLanesRefreshSpy = @spy(@_getSwimLanes(), 'refreshWithNewModelType')
      typeCombo = @_getTypeCombo()
      newValue = 'HierarchicalRequirement'
      typeCombo.fireEvent('select', typeCombo, [typeCombo.findRecordByValue(newValue)])

      expect(swimLanesRefreshSpy).toHaveBeenCalledOnce()
      expect(swimLanesRefreshSpy.getCall(0).args[0]).toBe newValue

  describe 'includes the correct swimlane', ->
    helpers
      assertFieldIsIncluded: (config) ->
        field = Ext.merge
          attributeDefinition:
            AttributeType: 'BOOLEAN'
            Constrained: false
            Custom: false
          , config
        expect(@isAllowedFieldFn(field)).toBe true

      assertFieldIsExcluded: (config) ->
        field = Ext.merge
          attributeDefinition:
            AttributeType: 'BOOLEAN'
            Constrained: false
            Custom: false
        , config
        expect(@isAllowedFieldFn(field)).toBe false

    beforeEach ->
      @createSettings().then =>
        @isAllowedFieldFn = @_getSwimLanes().isAllowedFieldFn

    describe 'standard fields', ->

      describe 'should have', ->
        it 'booleans', ->
          @assertFieldIsIncluded()

        it 'quantity', ->
          @assertFieldIsIncluded(attributeDefinition: AttributeType: 'QUANTITY')

        it 'dropdowns', ->
          @assertFieldIsIncluded(attributeDefinition: AttributeType: 'STRING', Constrained: true)

        it 'constrained objects', ->
          @assertFieldIsIncluded(attributeDefinition: AttributeType: 'OBJECT', Constrained: true)

        it 'unconstrained objects', ->
          @assertFieldIsIncluded(attributeDefinition: AttributeType: 'OBJECT', Constrained: false)

      describe 'should NOT have', ->

        it 'weblinks', ->
          @assertFieldIsExcluded(attributeDefinition: AttributeType: 'WEB_LINK')

        it 'string', ->
          @assertFieldIsExcluded(attributeDefinition: AttributeType: 'STRING')

        it 'text', ->
          @assertFieldIsExcluded(attributeDefinition: AttributeType: 'TEXT')

        it 'date', ->
          @assertFieldIsExcluded(attributeDefinition: AttributeType: 'DATE')

        it 'decimals', ->
          @assertFieldIsExcluded(attributeDefinition: AttributeType: 'DECIMAL')

        it 'integers', ->
          @assertFieldIsExcluded(attributeDefinition: AttributeType: 'INTEGER')

        it 'PortfolioItemType', ->
          @assertFieldIsExcluded(attributeDefinition: ElementName: 'PortfolioItemType', AttributeType: 'OBJECT')

    describe 'custom fields', ->
      describe 'should have', ->

        it 'booleans', ->
          @assertFieldIsIncluded(attributeDefinition: Custom: true)

        it 'decimals', ->
          @assertFieldIsIncluded(attributeDefinition: AttributeType: 'DECIMAL', Custom: true)

        it 'integers', ->
          @assertFieldIsIncluded(attributeDefinition: AttributeType: 'INTEGER', Custom: true)

        it 'dropdowns', ->
          @assertFieldIsIncluded(attributeDefinition: AttributeType: 'STRING', Constrained: true, Custom: true)

    describe 'should NOT have', ->

      it 'weblinks', ->
        @assertFieldIsExcluded(attributeDefinition: AttributeType: 'WEB_LINK', Custom: true)

      it 'string', ->
        @assertFieldIsExcluded(attributeDefinition: AttributeType: 'STRING', Custom: true)

      it 'text', ->
        @assertFieldIsExcluded(attributeDefinition: AttributeType: 'TEXT', Custom: true)

      it 'date', ->
        @assertFieldIsExcluded(attributeDefinition: AttributeType: 'DATE', Custom: true)

  describe 'includes the correct order fields', ->

    it 'refreshes the group by combo when the type changes', ->
      @createSettings(type: 'Defect').then =>
        orderRefreshSpy = @spy @_getOrder(), 'refreshWithNewModelType'
        typeCombo = @_getTypeCombo()
        newValue = 'HierarchicalRequirement'
        typeCombo.fireEvent('select', typeCombo, [typeCombo.findRecordByValue(newValue)])

        expect(orderRefreshSpy).toHaveBeenCalledOnce()
        expect(orderRefreshSpy.getCall(0).args[0]).toBe newValue
        expect(orderRefreshSpy.getCall(0).args[1]).toBe typeCombo.context

    it 'should have sortable fields', ->
      @createSettings().then =>
        _.each @_getOrder().getStore().getRange(), (field) ->
          expect(field.get('fieldDefinition').attributeDefinition.Sortable).toBe true

    it 'defaults to the rank field', ->
      @createSettings().then =>
        expect(@_getOrder().getValue()).toBe 'DragAndDropRank'

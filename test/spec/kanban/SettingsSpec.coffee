Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.kanban.Settings'
]

describe 'Rally.apps.kanban.Settings', ->
  helpers
    createSettings: (settings={}, contextValues) ->
      @ajax.whenQueryingAllowedValues('hierarchicalrequirement', 'ScheduleState').respondWith ['Defined', 'In-Progress', 'Completed', 'Accepted']
      settingsReady = @stub()
      context = @_getContext contextValues
      @container = Ext.create 'Rally.app.AppSettings',
        renderTo: 'testDiv'
        context: context
        settings: Ext.apply
          groupByField: 'ScheduleState'
        , settings
        fields: Rally.apps.kanban.Settings.getFields context
        listeners:
          appsettingsready: settingsReady

      @waitForCallback settingsReady

    _getContext: (context) ->
      Ext.create 'Rally.app.Context',
        initialValues: Ext.apply
          project:
            _ref: '/project/1'
            Name: 'Project 1'
          workspace:
            WorkspaceConfiguration:
              DragDropRankingEnabled: true
        , context

    _getFieldAt: (index) -> @container.down('form').form.getFields().getAt index

    _getSwimLanes: -> @_getFieldAt 2


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

        it 'dropdowns', ->
          @assertFieldIsIncluded(attributeDefinition: AttributeType: 'STRING', Constrained: true)

        it 'objects', ->
          @assertFieldIsIncluded(attributeDefinition: AttributeType: 'OBJECT', Constrained: true)

      describe 'should NOT have', ->

        it 'quantity', ->
          @assertFieldIsExcluded(attributeDefinition: AttributeType: 'QUANTITY')

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

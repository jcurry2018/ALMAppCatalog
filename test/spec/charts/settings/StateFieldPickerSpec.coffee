Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.charts.settings.StateFieldPicker',
  'Rally.ui.combobox.FieldComboBox'
  'Rally.test.mock.SnapshotAjaxBuilder'
]

describe 'Rally.apps.charts.settings.StateFieldPicker', ->

  afterEach ->
    # unstub the method to cleanup
    Rally.data.wsapi.Model.getFields.restore()
    Rally.test.destroyComponentsOfQuery('rallychartssettingsstatefieldpicker')
    Rally.test.destroyComponentsOfQuery('rallyfieldvaluecombobox')
    Rally.test.destroyComponentsOfQuery('rallyfieldcombobox')

  beforeEach ->
    @config =
      stateFieldName: 'KanbanState'
      stateFieldValues: 'V1,V2'
      timeFrameQuantity: 10
      timeFrameUnit: 'day'

  helpers
    allowedValue: (value) -> {
      StringValue: value,
      get: (v)->
          value
      }

    createPicker: (settings = {}) ->
      me = @
      getAllowedValueStore = () ->
        load : (args) ->
          # scoping is off since i'm stubbing out the model (below)
          # so i have to kind of 'fix' the scoping by merging the requester
          # with 'args' so that 'this' will work.
          Ext.merge(args,args.requester)
          args.callback([ me.allowedValue("V1"), me.allowedValue("V2") ])

      getType = ->
        @attributeDefinition.AttributeType.toLowerCase()

      # I'm not convinced this is the appropriate way to do this, but it definitely works although it also
      # requires some magic (above)
      @stub Rally.data.wsapi.Model, "getFields", ->
        [
          { name: "c_KanbanState", displayName: "Kanban State", attributeDefinition: { AttributeType: "STRING", hidden: false, ReadOnly: false, Constrained: true }, getAllowedValueStore, getType}
          { name: "ScheduleState", displayName: "Schedule State", attributeDefinition: { AttributeType: "STRING", hidden: false, ReadOnly: false, Constrained: true }, getAllowedValueStore, getType}
          { name: "TaskEstimateTotal", displayName: "Task Estimate Total", attributeDefinition: { AttributeType: "DOUBLE", hidden: false, ReadOnly: true, Constrained: false }, getAllowedValueStore, getType}
        ]


      @app = Ext.create('Rally.apps.charts.settings.StateFieldPicker',
          renderTo: 'testDiv'
          settings: settings
          listeners:
            ready: ->
              Rally.BrowserTest.publishComponentReady @
        )


  it 'shows only the filtered items when expanded', ->
    picker = @createPicker(@config)
    @waitForComponentReady(picker).then (p) =>
      combo = p.down('rallyfieldcombobox')
      combo.expand();
      expect(combo.getPicker().getNodes().length).toBe 2

  it 'all field values are shown when expanded', ->
    picker = @createPicker(@config)
    @waitForComponentReady(picker).then (p) =>
      combo = p.down('rallyfieldvaluecombobox')
      combo.expand();
      expect(combo.getPicker().getNodes().length).toBe 2

  # This must be last or things break
  it 'accepts and stores the configuration values passed in', ->
    x = @createPicker(@config)
    @waitForComponentReady(x).then (p) =>
      expect(p.settings).not.toBe undefined
      expect(p.settings.stateFieldName).toBe "KanbanState"
      expect(p.settings.stateFieldValues).toBe "V1,V2"
      expect(p.settings.timeFrameQuantity).toBe 10
      expect(p.settings.timeFrameUnit).toBe 'day'

  it 'shows the initial value passed in for the state field name', ->
    picker = @createPicker(@config)
    @waitForComponentReady(picker).then (p) =>
      combo = Ext.ComponentQuery.query('rallyfieldcombobox')[0]
      expect(combo.getValue()).toBe "c_KanbanState"

  it 'shows the initial value passed in for the state field values', ->
    picker = @createPicker(@config)
    @waitForComponentReady(picker).then (p) =>
      combo = Ext.ComponentQuery.query('rallyfieldvaluecombobox')[0]
      value = combo.getValue()
      expect(value).toEqual ["V1","V2"]


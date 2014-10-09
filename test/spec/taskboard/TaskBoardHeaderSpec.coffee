Ext = window.Ext4 || window.Ext

describe 'Rally.apps.taskboard.TaskBoardHeader', ->

  helpers
    createHeader: (config) ->
      table = Ext.get('testDiv').createChild tag: 'table'
      recordData = @mom.getData('userstory')[0]
      recordData.Recycled = false
      @header = Ext.create 'Rally.apps.taskboard.TaskBoardHeader', Ext.apply
        columns: [
          { value: 'column 1', isHidden: -> false }
        ]
        value: recordData
        fieldDef: {getType: -> 'foo'}
        renderTo: table
      , config

    getFormattedIdLinkEl: () ->
      @header.getEl().down('.formatted-id-link')

    onMouseEnter: () ->
      # calling a private so the creation of a popover actually can be tested :(
      @header._showWorkProductPopover()

  afterEach ->
    @header?.destroy()

  it 'should register mouseenter handler for formatted id link after render', ->
    onSpy = @spy(Ext.dom.Element::, 'on')
    @createHeader()

    expect(onSpy.callCount).toBe 1
    expect(onSpy.calledOn(@getFormattedIdLinkEl())).toBe true
    expect(onSpy.calledWith('mouseenter')).toBe true

  it 'should unregister mouseenter handler for formatted id link before destroy', ->
    @createHeader()
    unSpy = @spy(Ext.dom.Element::, 'un')
    formattedIdLinkEl = @getFormattedIdLinkEl()
    @header.destroy()

    expect(unSpy.callCount).toBe 1
    expect(unSpy.calledOn(formattedIdLinkEl)).toBe true
    expect(unSpy.calledWith('mouseenter')).toBe true

  it 'should create a work product popover', ->
    @createHeader()
    bakeStub = @stub Rally.ui.popover.PopoverFactory, 'bake'
    @onMouseEnter()

    expect(bakeStub.callCount).toBe 1

  it 'should not create a work product popover if one already exists', ->
    @createHeader()
    Ext.get('testDiv').createChild id: 'work-product-popover'
    bakeStub = @stub Rally.ui.popover.PopoverFactory, 'bake'
    @onMouseEnter()

    expect(bakeStub.callCount).toBe 0

Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.iterationtrackingboard.StatsBannerField'
]

describe 'Rally.apps.iterationtrackingboard.StatsBannerField', ->
  helpers
    createField: (showStatsBanner) ->
      @field = Ext.create 'Rally.apps.iterationtrackingboard.StatsBannerField',
        renderTo: 'testDiv'
        value:
          showStatsBanner: showStatsBanner

  it 'should set initial showStatsBanner value to config', ->
    @createField(false)
    expect(@field.getSubmitData().showStatsBanner).toBe false

  it 'should return correct showStatsBanner value', ->
    @createField(false)
    @field.down('rallycheckboxfield').setValue(true)
    expect(@field.getSubmitData().showStatsBanner).toBe true


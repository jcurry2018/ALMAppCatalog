Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.iterationtrackingboard.statsbanner.IterationProgressDialogChartToggle'
]

describe 'Rally.apps.iterationtrackingboard.statsbanner.IterationProgressDialogChartToggle', ->
  describe 'config:startingIndex', ->
    it 'should set the active button to the starting index', ->

      Ext.create('Rally.apps.iterationtrackingboard.statsbanner.IterationProgressDialogChartToggle'
        startingIndex: 2
        renderTo: 'testDiv'
      )

      button = Ext.DomQuery.selectNode('.cumulativeflow')
      expect(button).toHaveCls('rly-active')

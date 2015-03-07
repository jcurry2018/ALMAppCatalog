Ext = window.Ext4 || window.Ext

describe 'Rally.apps.iterationtrackingboard.statsbanner.BannerWidget', ->

  helpers
    createPane: (config={}) ->
      @pane = Ext.create 'Rally.apps.iterationtrackingboard.statsbanner.BannerWidget', _.defaults config,
        renderTo: 'testDiv'

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'almbannerwidget'

  describe 'expand / collapse', ->

    it 'initializes expanded to true', ->
      @createPane()
      expect(@pane.expanded).toBe true

    it 'sets expanded to true when passed in', ->
      @createPane expanded: true
      expect(@pane.expanded).toBe true

    it 'sets expanded to false when passed in', ->
      @createPane expanded: false
      expect(@pane.expanded).toBe false

    it 'sets expanded to false when collapsed', ->
      @createPane expanded: true
      @pane.collapse()
      expect(@pane.expanded).toBe false

    it 'sets expanded to true when expanded', ->
      @createPane expanded: false
      @pane.expand()
      expect(@pane.expanded).toBe true

    it 'hides expanded widget when collapsed', ->
      @createPane expanded: true
      @pane.collapse()
      expect(@pane.getEl().down('.expanded-widget').isVisible()).toBeFalsy()
      expect(@pane.getEl().down('.collapsed-widget').isVisible()).toBeTruthy()

    it 'hides collapsed widget when expanded', ->
      @createPane expanded: false
      @pane.expand()
      expect(@pane.getEl().down('.expanded-widget').isVisible()).toBeTruthy()
      expect(@pane.getEl().down('.collapsed-widget').isVisible()).toBeFalsy()
Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.app.TimeboxScope',
  'Rally.data.wsapi.artifact.Store'
]

describe 'Rally.apps.iterationtrackingboard.StatsBanner', ->

  helpers
    createBanner: (config={})->
      timeboxScope = config.scope || Ext.create 'Rally.app.TimeboxScope', record: @mom.getRecord 'iteration'
      @banner = Ext.create 'Rally.apps.iterationtrackingboard.StatsBanner', Ext.apply(
        renderTo: 'testDiv'
        context:
          getTimeboxScope: -> timeboxScope
          getScopedStateId: -> 'stateId'
          getDataContext: -> Rally.environment.getContext().getDataContext()
        items: [{xtype: 'bannerwidget'}]
        , config)

  beforeEach ->
    us = @mom.getData 'userstory'
    @ajax.whenQuerying('artifact').respondWith us

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'statsbanner'

  describe 'constructor', ->
    it 'should set _isRootLayout to true when optimizeLayouts is passed', ->
      @createBanner(
        optimizeLayouts: true
      )
      expect(@banner.isLayoutRoot()).toBe true

    it 'should default to isRootLayout to false when it has a parent container', ->
      @createBanner()
      try
        container = Ext.create('Ext.container.Container', items: [@banner])
        expect(@banner.isLayoutRoot()).toBe false
      finally
        container.destroy()

  describe 'initComponent', ->

    describe 'item defaults', ->
      it 'should apply store to intance items not class items', ->
        @createBanner()

        expect(_.has(@banner.items.get(0), 'store')).toBe true
        expect(_.has(@banner.self.prototype.items[0], 'store')).toBe false

    describe 'Rally.Message handlers', ->
      it 'should update in response to Rally.Message.object* and Rally.Message.bulk* messages', ->
        @createBanner()
        loadSpy = @spy @banner.store, 'load'
        for message in ['objectCreate', 'objectUpdate', 'bulkUpdate', 'bulkImport', 'objectDestroy']
          Rally.environment.getMessageBus().publish Rally.Message[message], @mom.getData 'userstory'
          expect(loadSpy.callCount).toEqual 1
          loadSpy.reset()

      it 'should not update when unscheduled', ->
        @createBanner scope: Ext.create 'Rally.app.TimeboxScope', type: 'iteration'
        loadSpy = @spy @banner.store, 'load'
        Rally.environment.getMessageBus().publish Rally.Message.objectCreate, @mom.getData 'userstory'
        expect(loadSpy.callCount).toBe 0

    describe 'Artifact Store', ->
      it 'should get correct models', ->
        @createBanner()
        expect(@banner.store.models).toEqual ['User Story', 'Defect', 'Defect Suite', 'Test Set']

      it 'should fetch fields correctly', ->
        @createBanner()
        expect(@banner.store.fetch).toEqual ['Defects:summary[State;ScheduleState+Blocked]',
                                             'PlanEstimate', 'Requirement', 'FormattedID', 'Name', 'Blocked', 'BlockedReason','ScheduleState', 'State', 'Tasks:summary[State+Blocked]', 'TestCases']

      it 'should filter correctly', ->
        @createBanner()
        filters = @banner.store.filters.getRange()
        expect(filters.length).toBe 1
        expect(filters[0].toString()).toBe @banner.context.getTimeboxScope().getQueryFilter().toString()

      it 'should set context correctly', ->
        @createBanner()
        expect(@banner.store.context).toEqual @banner.context.getDataContext()

      it 'should set limit correctly', ->
        @createBanner()
        expect(@banner.store.limit).toEqual Infinity

      it 'should load store if there is a timebox', ->
        loadSpy = @spy Rally.data.wsapi.artifact.Store::, 'load'
        @createBanner()
        expect(loadSpy).toHaveBeenCalled()

      it 'should not load from store if there is no timebox', ->
        loadSpy = @spy Rally.data.wsapi.artifact.Store::, 'load'
        @createBanner scope: Ext.create 'Rally.app.TimeboxScope', type: 'iteration'
        expect(loadSpy).not.toHaveBeenCalled()

  describe 'persisting state', ->
    it 'should initialize to collapsed when no state is stored', ->
      @createBanner()
      @banner.applyState({})
      expect(@banner.expanded).toBeFalsy()

    it 'should set item\'s expanded states to the banner\'s default expanded state', ->
      @createBanner()
      @banner.applyState({})
      _.each @banner.items.getRange(), (item) ->
          expect(item.expanded).toBeFalsy()

    it 'should apply state when stored as expanded', ->
      @createBanner()
      @banner.applyState(expanded: true)
      expect(@banner.expanded).toBeTruthy()

    it 'should apply expanded state to items', ->
      @createBanner()
      @banner.applyState(expanded: true)
      _.each @banner.items.getRange(), (item) ->
          expect(item.expanded).toBeTruthy()

    it 'should apply state when stored as expanded', ->
      @createBanner()
      @banner.applyState(expanded: true)
      expect(@banner.expanded).toBeTruthy()

    it 'should listen for expand event and save new state', ->
      @createBanner()
      @banner.fireEvent('expand')
      expect(@banner.getState().expanded).toBeTruthy()

    it 'should listen for collapse event and save new state', ->
      @createBanner()
      @banner.fireEvent('collapse')
      expect(@banner.getState().expanded).toBeFalsy()

  describe 'expand/collapse all children items', ->
    it 'should listen for expand event and then expand the banner', ->
      @createBanner({expanded: false, items: [{xtype: 'statsbannercollapseexpand'}]})
      @click(css: '.collapse-expand').then =>
        expect(@banner.getEl()).not.toHaveCls('collapsed')
        _.each @banner.items.getRange(), (item) ->
          expect(item.getEl().down('.expanded-widget').isVisible()).toBeTruthy()
          expect(item.getEl().down('.collapsed-widget').isVisible()).toBeFalsy()

    it 'should listen for collapse event and then collapse the banner', ->
      @createBanner({expanded: true, items: [{xtype: 'statsbannercollapseexpand'}]})
      @click(css: '.collapse-expand').then =>
        expect(@banner.getEl()).toHaveCls('collapsed')
        _.each @banner.items.getRange(), (item) ->
          expect(item.getEl().down('.collapsed-widget').isVisible()).toBeTruthy()
          expect(item.getEl().down('.expanded-widget').isVisible()).toBeFalsy()

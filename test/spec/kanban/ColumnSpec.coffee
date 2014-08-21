Ext = window.Ext4 || window.Ext;

Ext.require [
  'Rally.app.Context'
  'Rally.apps.kanban.Column'
], ->

  describe 'Rally.apps.kanban.Column', ->

    beforeEach ->
      @stub(Rally.app.Context.prototype, 'getSubscription').returns StoryHierarchyEnabled: true
      @cardboardHelper = Rally.test.helpers.CardBoard

      @Model = Rally.test.mock.data.WsapiModelFactory.getUserStoryModel()

      @ajax.whenQuerying('userstory').respondWith()
      @ajax.whenQuerying('defect').respondWith()

    afterEach ->
      Ext.Array.forEach Ext.ComponentQuery.query('kanbancolumn'), (component) ->
        component.destroy()

    it 'should only show stories with no children', ->
      storeFilterSpy = @spy(Rally.apps.kanban.Column.prototype, 'getStoreFilter')
      @createColumn()

      expect(storeFilterSpy.returnValues[0][1].property).toBe 'DirectChildrenCount'
      expect(storeFilterSpy.returnValues[0][1].value).toBe 0

    it 'should have correct filter settings if hideReleasedCards is true', ->
      storeFilterSpy = @spy(Rally.apps.kanban.Column.prototype, 'getStoreFilter')
      @createColumn(hideReleasedCards:true)

      expect(storeFilterSpy.returnValues[0][2].property).toBe 'Release'
      expect(storeFilterSpy.returnValues[0][2].value).toBe null

    helpers
      createColumn: (config = {}) ->
        @cardboardHelper.createColumn(Ext.apply(
          columnClass: 'Rally.apps.kanban.Column'
          context: Rally.environment.getContext()
          value: 'Defined'
          attribute: 'ScheduleState'
          wipLimit: 0
          renderTo: 'testDiv'
          headerCell: Ext.get 'testDiv'
          models: [@Model]
          , config)
        )

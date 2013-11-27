Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.Proxy'
  'Rally.apps.roadmapplanningboard.Model'
  'Rally.ui.notify.Notifier'
]

describe 'Rally.apps.roadmapplanningboard.Proxy', ->

  beforeEach ->
    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()

  afterEach ->
    Deft.Injector.reset()

  describe '#buildRequest', ->

    beforeEach ->
      @proxy = Ext.create 'Rally.apps.roadmapplanningboard.Proxy',
        url: ''
      @operation = { params: {} }

    it 'should add withCredentials to the request', ->
      expect(@proxy.buildRequest(@operation).withCredentials).toBe true

  describe '#buildUrl', ->

    beforeEach ->
      @proxy = Ext.create 'Rally.apps.roadmapplanningboard.Proxy',
        url: 'foo/{fooId}/bar'
      @request = { url: '', operation: params: fooId: '123' }

    it 'should build the url and replace template items with operation parameters', ->
      expect(@proxy.buildUrl(@request)).toBe 'foo/123/bar'

  describe '#doRequest', ->

    beforeEach ->
      @request = { url: '', operation: params: fooId: '123' }
      @operation = { request: @request }
      @errorNotifySpy = @spy Rally.ui.notify.Notifier, 'showError'

    describe 'without error', ->
      beforeEach ->
        @proxy = Ext.create 'Rally.apps.roadmapplanningboard.Proxy',
          url: 'foo/{fooId}/bar'

      it 'should add workspace to operation', ->
        @proxy.doRequest(@operation, Ext.emptyFn, @).then =>
          expect(@operation.params.workspace).toBe '12345678-1234-1234-1234-12345678'

    describe 'with error', ->

      beforeEach ->
        Deft.Injector.configure
          uuidMapper: fn: ->
            getUuid: ->
              deferred = Ext.create 'Deft.promise.Deferred'
              deferred.reject('oh noes')
              deferred
        @proxy = Ext.create 'Rally.apps.roadmapplanningboard.Proxy',
          url: 'foo/{fooId}/bar'
        @proxy.doRequest @operation, Ext.emptyFn, @

      it 'should display an error notification', ->
        expect(@errorNotifySpy.lastCall.args[0].message).toEqual 'oh noes'



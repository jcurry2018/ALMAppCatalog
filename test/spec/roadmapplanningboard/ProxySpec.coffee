Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.Proxy'
  'Rally.apps.roadmapplanningboard.Model'
  'Rally.ui.notify.Notifier'
]

describe 'Rally.apps.roadmapplanningboard.Proxy', ->

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
      @request = { url: '', operation:
        params:
          fooId: '123' }

    it 'should build the url and replace template items with operation parameters', ->
      expect(@proxy.buildUrl(@request)).toBe 'foo/123/bar'

  describe '#doRequest', ->
    beforeEach ->
      @stub Rally.environment, 'getContext', () ->
        getWorkspace: () ->
          _refObjectUUID: '12345678-1234-1234-1234-12345678'
        getProject: () ->
          _refObjectUUID: '12345678-1234-1234-1234-12345679'
      @operation =
        allowWrite: -> false
      @proxy = Ext.create 'Rally.apps.roadmapplanningboard.Proxy',
        url: 'foo/123/bar'

    it 'should add workspace to operation', ->
      request = @proxy.doRequest(@operation, Ext.emptyFn, @)
      expect(request.operation.params.workspace).toBe '12345678-1234-1234-1234-12345678'

    it 'should add project to operation', ->
      request = @proxy.doRequest(@operation, Ext.emptyFn, @)
      expect(request.operation.params.project).toBe '12345678-1234-1234-1234-12345679'

    it 'should set noQueryScoping on operation when issuing request', ->
      request = @proxy.doRequest(@operation, Ext.emptyFn, @)
      expect(request.operation.noQueryScoping).toBe true



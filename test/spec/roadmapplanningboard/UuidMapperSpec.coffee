Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.UuidMapper'
  'Rally.test.mock.env.Global'
]

describe 'Rally.apps.roadmapplanningboard.UuidMapper', ->

  beforeEach ->
    @uuidMapper = Ext.create('Rally.apps.roadmapplanningboard.UuidMapper')
    @workspaceUuid = '12345678-1234-1234-1234-12345678'
    @projectUuid = '12345678-1234-1234-1234-12345679'

    # Can't do '@ajax.whenReading' since it will wrap in an array
    @getUuidFromWsapiStub = @stub @uuidMapper, '_getUuidFromWsapi', (domainObject) =>
      deferred = Ext.create('Deft.promise.Deferred')
      if domainObject.ObjectID is 1
        deferred.resolve @workspaceUuid
      else if domainObject.ObjectID is 2
        deferred.resolve @projectUuid
      else
        deferred.reject 'uuid not found'

      deferred.promise

    @mockWorkspace = ObjectID: 1
    @mockProject = ObjectID: 2

  describe '#getUuid', ->

    it 'should return a promise', ->
      expect(@uuidMapper.getUuid(@mockWorkspace).then).toBeDefined()

    it 'should resolve with the uuid of the domainObject', ->
      @uuidMapper.getUuid(@mockWorkspace).then (uuid) =>
        expect(uuid).toBe @workspaceUuid

    it 'should resolve with an array of uuids if passed an array of domainObjects', ->
      @uuidMapper.getUuid([@mockWorkspace, @mockProject]).then (uuids) =>
        expect(uuids).toEqual [@workspaceUuid, @projectUuid]

    it 'should reject with an error if a uuid cannot be found', ->
      promise = @uuidMapper.getUuid(ObjectID: 3)
      @waitForPromiseToRejectWith(promise, 'uuid not found')

    it 'should not make a request for the same uuid more than once', ->
      @uuidMapper.getUuid(@mockWorkspace).then (uuid) =>
        @uuidMapper.getUuid(@mockWorkspace).then (uuid) =>
          expect(@getUuidFromWsapiStub).toHaveBeenCalledOnce()

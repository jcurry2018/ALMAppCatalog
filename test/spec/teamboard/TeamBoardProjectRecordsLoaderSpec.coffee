Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.teamboard.TeamBoardProjectRecordsLoader'
]

describe 'Rally.apps.teamboard.TeamBoardProjectRecordsLoader', ->
  beforeEach ->
    @ajax.whenQuerying('project').respondWith []

  it 'should fetch the records specified', ->
    store = Rally.apps.teamboard.TeamBoardProjectRecordsLoader.load '1,2,3'

    expect(store).toOnlyHaveFilterStrings ['(((ObjectID = "1") OR (ObjectID = "2")) OR (ObjectID = "3"))']

  it 'should fetch the first 10 records if none are specified', ->
    store = Rally.apps.teamboard.TeamBoardProjectRecordsLoader.load()

    expect(store).toHaveNoFilters()
    expect(store.pageSize).toBe 10

  it 'should be able to fetch one record if oid specified as a number', ->
    store = Rally.apps.teamboard.TeamBoardProjectRecordsLoader.load 2

    expect(store).toOnlyHaveFilterStrings ['(ObjectID = "2")']

  it 'should call the callback when loaded', ->
    callback = @spy()
    Rally.apps.teamboard.TeamBoardProjectRecordsLoader.load '1,2,3', callback

    @waitForCallback callback
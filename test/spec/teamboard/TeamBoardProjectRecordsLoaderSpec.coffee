Ext = window.Ext4 || window.Ext

Ext.require ['Rally.apps.teamboard.TeamBoardProjectRecordsLoader']

describe 'Rally.apps.teamboard.TeamBoardProjectRecordsLoader', ->
  beforeEach ->
    @ajax.whenQuerying('project').respondWith []

  it 'should fetch the records specified', ->
    store = Rally.apps.teamboard.TeamBoardProjectRecordsLoader.load '1,2,3'
    expect(store).toOnlyHaveFilterString '(((ObjectID = "1") OR (ObjectID = "2")) OR (ObjectID = "3"))'

  it 'should fetch only the current project if none are specified', ->
    store = Rally.apps.teamboard.TeamBoardProjectRecordsLoader.load()
    expect(store).toOnlyHaveFilterString '(ObjectID = ' + Rally.environment.getContext().getProject().ObjectID + ')'

  it 'should be able to fetch one record if oid specified as a number', ->
    store = Rally.apps.teamboard.TeamBoardProjectRecordsLoader.load 2
    expect(store).toOnlyHaveFilterString '(ObjectID = "2")'

  it 'should call the callback when loaded', ->
    callback = @spy()
    Rally.apps.teamboard.TeamBoardProjectRecordsLoader.load '1,2,3', callback

    @waitForCallback callback

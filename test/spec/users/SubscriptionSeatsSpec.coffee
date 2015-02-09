Ext = window.Ext4 || window.Ext;

describe 'Rally.apps.users.SubscriptionSeats', ->
  helpers
    whenQueryingSeatsRespondWith: (options) ->
      @ajax.whenQueryingEndpoint('/licensing/seats.sp').respondWith options

    assertSeatInformationIs: (expected) ->
      Ext.create 'Rally.apps.users.SubscriptionSeats',
        contextPath: ''
        targetId: 'testDiv'
        workspaceOid: 1

      expect(Ext.fly('testDiv').down('span').getHTML()).toEqual expected

  it 'should display number of licenses remaining when seats are limited', ->
    @whenQueryingSeatsRespondWith HasUnlimitedSeats: false, NumberOfActiveUsers: 7, NumberOfPaidSeats: 13, NumberOfTotalSeats: 11, NumberOfUnpaidSeats: 3
    @assertSeatInformationIs '9 of 16 active user licenses remaining'

  it 'should display number of active licenses seats are unlimited', ->
    @whenQueryingSeatsRespondWith HasUnlimitedSeats: true, NumberOfActiveUsers: 4, NumberOfPaidSeats: -1, NumberOfTotalSeats: 25, NumberOfUnpaidSeats: 0
    @assertSeatInformationIs '4 active user licenses'

  describe 'when failing to retrive licensing information', ->
    afterEach ->
      @assertSeatInformationIs 'Unable to retrieve licensing information.'

    it 'works on errors', ->
      @ajax.whenQueryingEndpoint('/licensing/seats.sp').errorWith 'some sort of error'

    it 'works on a null response', ->
      @whenQueryingSeatsRespondWith HasUnlimitedSeats: null, NumberOfActiveUsers: null, NumberOfPaidSeats: null, NumberOfTotalSeats: null, NumberOfUnpaidSeats: null

    it 'works on an empty response', ->
      @whenQueryingSeatsRespondWith {}
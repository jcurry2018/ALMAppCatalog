Ext = window.Ext4 || window.Ext;

describe 'Rally.apps.users.SubscriptionSeats', ->
  helpers
    whenQueryingSeatsRespondWith: (object) ->
      @ajax.whenQueryingEndpoint('/licensing/seats.sp').respondWithString Ext.JSON.encode(object)

    assertSeatInformationIs: (expected) ->
      expect(Ext.create('Rally.apps.users.SubscriptionSeats', renderTo: 'testDiv').getEl().getHTML()).toEqual expected

  it 'should display number of licenses remaining when seats are limited', ->
    @whenQueryingSeatsRespondWith HasUnlimitedSeats: false, NumberOfActiveUsers: 7, NumberOfPaidSeats: 13, NumberOfTotalSeats: 11, NumberOfUnpaidSeats: 3
    @assertSeatInformationIs '9 of 16 active user licenses remaining'

  it 'should display number of active licenses seats are unlimited', ->
    @whenQueryingSeatsRespondWith HasUnlimitedSeats: true, NumberOfActiveUsers: 4, NumberOfPaidSeats: -1, NumberOfTotalSeats: 25, NumberOfUnpaidSeats: 0
    @assertSeatInformationIs '4 active user licenses'

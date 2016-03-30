(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.users.SubscriptionSeats', {
        alias: 'widget.rallysubscriptionseats',
        extend: 'Ext.Component',
        mixins: ['Rally.Messageable'],

        autoEl: 'span',
        cls: 'subscription-seats',

        afterRender: function() {
            this.callParent(arguments);

            this.subscribe(this, Rally.Message.objectUpdate, this._updateSeatInformation, this);
            this.subscribe(this, Rally.Message.recordUpdateSuccess, this._updateSeatInformation, this);
            this.subscribe(this, Rally.Message.objectCreate, this._updateSeatInformation, this);
            this.subscribe(this, Rally.Message.objectDestroy, this._updateSeatInformation, this);

            this._updateSeatInformation();
        },

        _updateSeatInformation: function() {
            Ext.Ajax.request({
                method:'GET',
                requester: this,
                scope: this,
                success: this._successHandler,
                url: Rally.environment.getServer().getContextPath() + '/licensing/seats.sp'
            });
        },

        _successHandler: function(response) {
            var responseJson = Ext.JSON.decode(response.responseText);
            var seatsAvailable = responseJson.NumberOfPaidSeats + responseJson.NumberOfUnpaidSeats;
            var el = this.getEl();

            if (el) {
                el.update(
                    responseJson.HasUnlimitedSeats ?
                    responseJson.NumberOfActiveUsers + ' active user licenses' :
                    (seatsAvailable - responseJson.NumberOfActiveUsers) + ' of ' + seatsAvailable + ' active user licenses remaining'
                );
            }
        }
    });
})();
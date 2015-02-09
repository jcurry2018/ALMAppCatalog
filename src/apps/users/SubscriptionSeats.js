(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.users.SubscriptionSeats', {
        extend: 'Ext.Component',
        mixins: {
            messageable: 'Rally.Messageable'
        },

        targetElement: null,
        workspaceOid: null,
        numberOfPaidSeats: null,
        numberOfUnpaidSeats: null,
        numberOfActiveUsers: null,
        numberOfTotalSeats: null,
        hasUnlimitedSeats: null,

        initComponent: function(config) {
            this.callParent(arguments);
            this.subscribe(this, Rally.Message.objectUpdate, this.setSeatInformation, this);
            this.subscribe(this, Rally.Message.recordUpdateSuccess, this.setSeatInformation, this);
            this.subscribe(this, Rally.Message.objectCreate, this.setSeatInformation, this);
            this.subscribe(this, Rally.Message.objectDestroy, this.setSeatInformation, this);
            this.setSeatInformation();
        },

        setSeatInformation: function() {
            Ext.Ajax.request({
                requester: this,
                method:'GET',
                url: Rally.environment.getServer().getContextPath() + '/licensing/seats.sp',
                params: {
                    workspaceOid: this.workspaceOid
                },
                scope:this,
                success: function(response) {
                    this._successHandler(response);
                },
                failure: function (response) {
                    this._resetSeatInformation();
                    Ext.get(this.targetId).update(this._textForSeatsRemainingFailureMessage());
                }
            });
        },

        _successHandler: function(response) {
            this._extractSeatInformationFromResponse(response.responseText);
            Ext.get(this.targetId).update(this._addComponentToRightOfButton());
        },

        _calculateSeatsAvailable: function() {
            return this.numberOfPaidSeats + this.numberOfUnpaidSeats;
        },

        _calculateRemainingSeats: function() {
            return this._calculateSeatsAvailable() - this.numberOfActiveUsers;
        },

        _addComponentToRightOfButton: function() {
            if (typeof this.numberOfTotalSeats !== "undefined" && this.numberOfTotalSeats !== null) {
                return this._styleMessage(this._getTextBasedOnSubscriptionType());
            } else {
                return this._textForSeatsRemainingFailureMessage();
            }
        },

        _textForSeatsRemainingFailureMessage: function() {
            return this._styleMessage('Unable to retrieve licensing information.');
        },

        _getTextBasedOnSubscriptionType: function() {
            if (this.hasUnlimitedSeats) {
                return this.numberOfActiveUsers + ' active user licenses';
            } else {
                return this._calculateRemainingSeats() + ' of ' + this._calculateSeatsAvailable() + ' active user licenses remaining';
            }
        },

        _styleMessage: function(message) {
            return '<span style="color:#666;padding-left:5px;">' + message + '</span>';
        },

        _extractSeatInformationFromResponse: function(responseText) {
            if ( responseText ) {
                var res = Ext.JSON.decode(responseText);
                //  Need to handle the different response we get back when mocking for tests. Sigh.
                if (res.QueryResult) {
                    res = res.QueryResult.Results;
                }
                this.numberOfPaidSeats = res.NumberOfPaidSeats;
                this.numberOfUnpaidSeats = res.NumberOfUnpaidSeats;
                this.numberOfActiveUsers = res.NumberOfActiveUsers;
                this.numberOfTotalSeats = res.NumberOfTotalSeats;
                this.hasUnlimitedSeats = res.HasUnlimitedSeats;
            } else {
                this._resetSeatInformation();
            }
        },

        _resetSeatInformation: function() {
            this.numberOfPaidSeats = null;
            this.numberOfUnpaidSeats = null;
            this.numberOfActiveUsers = null;
            this.numberOfTotalSeats = null;
            this.hasUnlimitedSeats = null;
        }
    });
})();
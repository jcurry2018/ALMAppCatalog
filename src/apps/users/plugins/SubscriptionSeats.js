(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.users.plugins.SubscriptionSeats', {
        alias: 'plugin.rallysubscriptionseats',
        extend:'Ext.AbstractPlugin',
        requires: [
            'Rally.apps.users.SubscriptionSeats'
        ],
        mixins: [
            'Rally.ui.gridboard.plugin.GridBoardControlShowable'
        ],

        headerPosition: 'left',
        init: function(cmp) {
            this.callParent(arguments);
            this.showControl();
        },

        getControlCmpConfig: function() {
            return {
                xtype: 'rallysubscriptionseats'
            };
        }
    });
})();
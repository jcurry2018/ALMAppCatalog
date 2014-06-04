(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.TeamBoardCard', {
        alias: 'widget.rallyteamboardcard',
        extend: 'Rally.ui.cardboard.Card',
        requires: [
            'Rally.apps.teamboard.TeamBoardCardContentLeft',
            'Rally.apps.teamboard.TeamBoardCardContentRight',
            'Rally.apps.teamboard.TeamBoardUtil',
            'Rally.util.User'
        ],

        inheritableStatics: {
            getFetchFields: function() {
                return ['FirstName', 'LastName', 'Role'];
            }
        },

        setupPlugins: function(){
            return [{
                ptype: 'rallyteamboardcardcontentleft'
            }, {
                ptype: 'rallyteamboardcardcontentright'
            }];
        }
    });

})();
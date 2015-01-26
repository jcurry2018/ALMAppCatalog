/*jshint bitwise: false*/
(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.TeamBoardCard', {
        alias: 'widget.rallyteamboardcard',
        extend: 'Rally.ui.cardboard.Card',
        requires: [
            'Rally.apps.teamboard.TeamBoardUtil',
            'Rally.apps.teamboard.plugin.TeamBoardCardContentLeft',
            'Rally.apps.teamboard.plugin.TeamBoardCardContentRight',
            'Rally.apps.teamboard.plugin.TeamBoardCardPopover',
            'Rally.util.User'
        ],

        inheritableStatics: {
            getFetchFields: function() {
                return ['FirstName', 'LastName', 'Role'];
            },

            //From http://stackoverflow.com/questions/3426404/create-a-hexadecimal-colour-based-on-a-string-with-javascript
            stringToColour: function(str) {
                var i, hash = 0, colour = '#';
                for (i = 0; i < str.length; ){
                    hash = str.charCodeAt(i++) + ((hash << 5) - hash);
                }
                for (i = 0; i < 3; ){
                    colour += ("00" + ((hash >> i++ * 8) & 0xFF).toString(16)).slice(-2);
                }
                return colour;
            }
        },

        setupPlugins: function(){
            return ['rallyteamboardcardcontentleft', 'rallyteamboardcardcontentright', 'rallyteamboardcardpopover'];
        },

        _buildHtml: function() {
            if(this.groupBy) {
                this.record.set('DisplayColor', this.self.stringToColour(this.record.get(this.groupBy)));
            }

            return this.callParent(arguments);
        }
    });

})();
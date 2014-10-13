(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.plugin.TeamBoardCardContentRight', {
        alias: 'plugin.rallyteamboardcardcontentright',
        extend: 'Ext.AbstractPlugin',
        requires: ['Rally.ui.cardboard.plugin.CardContentRight'],

        init: function (card) {
            card.contentRightPlugin = this;
        },

        getHtml: function() {
            return '<td class="rui-card-right-side">' +
                    '<div class="' + Rally.ui.cardboard.plugin.CardContentRight.TOP_SIDE_CLS + '"></div>' +
                    '<div class="' + Rally.ui.cardboard.plugin.CardContentRight.BOTTOM_SIDE_CLS + '"></div>' +
                   '</td>';
        }
    });
})();
(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.plugin.TeamBoardCardContentLeft', {
        alias: 'plugin.rallyteamboardcardcontentleft',
        extend: 'Rally.ui.cardboard.plugin.CardContentLeft',

        getCardHeader: function(){
            var record = this.card.getRecord();

            var name = record.get('FirstName') && record.get('LastName') ? record.get('FirstName') + ' ' + record.get('LastName') : record.get('_refObjectName');
            var role = record.get('Role') === 'None' ? '' : record.get('Role');

            return '<table class="card-header">' +
                '<tr>' +
                '<td>' +
                '<img src="' + Rally.util.User.getProfileImageUrl(40, record.get('_ref')) + '">' +
                '</td>' +
                '<td class="card-header-spacer"></td>' +
                '<td class="card-header-user-info">' +
                '<div class="team-member-name">' + Rally.apps.teamboard.TeamBoardUtil.linkToAdminPage(record, name) + '</div>' +
                '<div class="team-member-role">' + role + '</div>' +
                '</td>' +
                '</tr>' +
                '</table>';
        },

        getHtml: function() {
            return this.callParent(arguments).replace(/<div class="status-content">/,
                    '<div class="status-content">' +
                    this._statusFieldHtml('AssociatedUserStories', 'story') +
                    this._statusFieldHtml('AssociatedDefects', 'defect') +
                    this._statusFieldHtml('AssociatedTasks', 'task') +
                    this._statusFieldHtml('AssociatedDiscussion', 'comment')
            );
        },

        _statusFieldHtml: function(fieldName, iconName) {
            return '<div class="field-content status-field ' + fieldName + '"><div class="status-value"><span class="icon-' + iconName + ' associated-artifacts-icon"></span></div></div>';
        }
    });
})();
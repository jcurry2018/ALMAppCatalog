(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.TeamBoardUtil', {
        requires: [
            'Rally.nav.DetailLink'
        ],
        singleton: true,

        linkToAdminPage: function(record, text, subPage){
            if(Rally.environment.getContext().getPermissions().isWorkspaceOrSubscriptionAdmin() || this._isProjectAdmin(record)){
                return Rally.nav.DetailLink.getLink({
                    record: record,
                    showHover: false,
                    subPage: subPage,
                    text: text
                });
            }else{
                return text;
            }
        },

        _isProjectAdmin: function(record) {
            var permissions = Rally.environment.getContext().getPermissions();
            return record.self.prettyTypeName === 'project' ? permissions.isProjectAdmin(record.get('_ref')) : permissions.isProjectAdminInAnyProject();
        }
    });

})();
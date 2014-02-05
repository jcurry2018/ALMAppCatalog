(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.util.UserPermissions', {
        config: {
            workspace: null,
            permissions: null
        },

        constructor: function (config) {
            this.initConfig(config);
        },

        isUserAdmin: function () {
            return this.permissions.isSubscriptionAdmin() || this.permissions.isWorkspaceAdmin(this.workspace._ref);
        }
    });
}).call(this);
(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.incompletestories.IncompleteStoriesApp', {
        extend: 'Rally.apps.customlist.CustomListApp',

        getAddNewConfig: function () {
            return Ext.apply(this.callParent(arguments), {disableAddButton: true});
        }
    });
})();

(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.customlist.CustomListApp', {
        extend: 'Rally.app.App',

        launch: function() {
            this.add({
                xtype: 'component',
                html: '<div style="height:100%;background-color: magenta; font-family: ComicSansMS; font-size: 50pt">Hi Mike!</div>'
            });
        }
    });
})();

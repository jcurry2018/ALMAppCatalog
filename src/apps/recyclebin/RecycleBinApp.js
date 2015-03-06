(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.recyclebin.RecycleBinApp', {
        extend: 'Rally.app.GridBoardApp',

        columnNames: ['ID','Name', 'Type','DeletedBy','DeletionDate'],
        enableOwnerFilter: false,
        enableAddNew: false,
        enablePrint: false,
        enableCsvExport: false,
        modelNames: ['RecycleBinEntry'],
        statePrefix: 'recyclebin',

        getGridConfig: function () {
            return _.merge(this.callParent(arguments), {
                enableRanking: false,
                enableBulkEdit: false,
                noDataItemName: 'deleted item'
            });
        },

        getFilterControlConfig: function () {
            return {
                blackListFields: ['ObjectID']
            };
        }
    });
})();
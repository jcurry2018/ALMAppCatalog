(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.recyclebin.RecycleBinApp', {
        extend: 'Rally.app.GridBoardApp',

        columnNames: ['ID','Name', 'Type','DeletedBy','DeletionDate'],
        modelNames: ['RecycleBinEntry'],
        statePrefix: 'recyclebin',
        enableOwnerFilter: false,
        enableAddNew: false,
        enablePrint: false,
        enableCsvExport: false,

        getGridConfig: function () {
            return _.merge(this.callParent(arguments), {
                enableRanking: false,
                enableBulkEdit: false,
                noDataItemName: 'deleted item'
            });
        },

        getFilterControlConfig: function () {
            return {
                margin: '3 9 3 0',
                blackListFields: ['ObjectID']
            };
        },

        getFieldPickerConfig: function() {
            return {
                margin: '3 9 3 -20'
            };
        }
    });
})();
(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.backlog.BacklogApp', {
        extend: 'Rally.app.GridBoardApp',
        requires: [
            'Rally.ui.gridboard.plugin.GridBoardActionsMenu',
            'Rally.ui.grid.TreeGridPrintDialog',
            'Rally.ui.dialog.CsvImportDialog',
            'Rally.ui.grid.GridCsvExport'
        ],

        columnNames: ['FormattedID','DisplayColor','Name','ScheduleState','Owner','PlanEstimate'],
        modelNames: ['hierarchicalrequirement', 'defect', 'defectsuite'],
        statePrefix: 'backlog',

        getGridConfig: function () {
            return _.merge(this.callParent(arguments), {
                noDataItemName: 'backlog'
            });
        },

        getPermanentFilters: function () {
            return [
                { property: 'Release', operator: '=', value: null },
                { property: 'Iteration', operator: '=', value: null },
                Rally.data.wsapi.Filter.or([
                    { property: 'State', operator: '!=', value: 'Closed' },
                    { property: 'TypeDefOid', operator: '!=', value: this._getTypeDefOidFor('defect') }
                ]),
                Rally.data.wsapi.Filter.or([
                    { property: 'DirectChildrenCount', operator: '=', value: '0' },
                    { property: 'TypeDefOid', operator: '!=', value: this._getTypeDefOidFor('hierarchicalrequirement') }
                ])
            ];
        },

        getGridStoreConfig: function () {
            return {
                enableHierarchy: false
            };
        },

        _getTypeDefOidFor: function(type) {
            return _.find(this.models, { typePath: type }).typeDefOid;
        }
    });
})();
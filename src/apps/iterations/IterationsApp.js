(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.iterations.IterationsApp', {
        extend: 'Rally.app.GridBoardApp',
        columnNames: ['Name', 'StartDate', 'EndDate', 'Project', 'PlannedVelocity', 'PlanEst', 'TaskEstimateTotal', 'TaskRemainingTotal', 'TaskActualTotal', 'State'],
        modelNames: ['iteration'],
        statePrefix: 'iteration',
        enableXmlExport: true,

        getAddNewConfig: function () {
            return Ext.apply(this.callParent(arguments), {
                additionalFields: [
                    {
                        xtype: 'rallydatefield',
                        emptyText: 'Select Start Date',
                        name: 'StartDate',
                        paramName: 'startDate',
                        allowBlank: false
                    },{
                        xtype: 'rallydatefield',
                        emptyText: 'Select End Date',
                        name: 'EndDate',
                        paramName: 'endDate',
                        allowBlank: false
                    }
                ],
                ignoredRequiredFields: ['State', 'Project', 'StartDate', 'EndDate', 'Name'],
                listeners: {
                    beforecreate: this._onBeforeCreate
                },
                minWidth: 800,
                openEditorAfterAddFailure: false,
                showAddWithDetails: true,
                showRank: false
            });
        },

        getGridConfig: function () {
            return _.merge(this.callParent(arguments), {
                enableSummaryRow: false,
                rowActionColumnConfig: {
                    menuOptions: {
                        showInlineAdd: false
                    }
                }
            });
        },

        getFieldPickerConfig: function () {
            var config = this.callParent(arguments) || {};
            config.gridFieldBlackList.push('UserIterationCapacities', 'Theme');
            return config;
        },

        _onBeforeCreate: function(addNew, record, params) {
            record.set('State', 'Planning');
        }
    });
})();
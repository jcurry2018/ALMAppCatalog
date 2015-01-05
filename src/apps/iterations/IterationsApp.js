(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.iterations.IterationsApp', {
        extend: 'Rally.app.GridBoardApp',
        columnNames: ['Name', 'Theme', 'StartDate', 'EndDate', 'PlannedVelocity', 'PlanEst', 'TaskEst', 'ToDo', 'Actuals', 'State'],
        modelNames: ['iteration'],
        statePrefix: 'iteration',

        getAddNewConfig: function () {
            return {
                showRank: false,
                showAddWithDetails: true,
                openEditorAfterAddFailure: true,
                ignoredRequiredFields: ['Name', 'State', 'Project'],
                minWidth: 600,
                additionalFields: [
                    {
                        xtype: 'rallydatefield',
                        emptyText: 'Select Start Date',
                        name: 'StartDate'
                    },{
                        xtype: 'rallydatefield',
                        emptyText: 'Select End Date',
                        name: 'EndDate'
                    }
                ],
                listeners: {
                    beforecreate: this._onBeforeCreate
                }
            };
        },

        _onBeforeCreate: function(addNew, record, params) {
            record.set('State', 'Planning');
        }
    });
})();
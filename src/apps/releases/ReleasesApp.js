(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.releases.ReleasesApp', {
        extend: 'Rally.app.GridBoardApp',
        cls: 'releases-app',
        enableOwnerFilter: false,
        enableRanking: false,
        modelNames: ['Release'],
        columnNames: ['Name','Theme','ReleaseStartDate','ReleaseDate','PlannedVelocity','State'],
        statePrefix: 'releases',

        getAddNewConfig: function () {
            return {
                showRank: false,
                showAddWithDetails: true,
                openEditorAfterAddFailure: true,
                ignoredRequiredFields: ['Name', 'State', 'Project', 'GrossEstimateConversionRatio'],
                minWidth: 800,
                additionalFields: [
                    {
                        xtype: 'rallydatefield',
                        emptyText: 'Select Start Date',
                        name: 'ReleaseStartDate'
                    },{
                        xtype: 'rallydatefield',
                        emptyText: 'Select Release Date',
                        name: 'ReleaseDate'
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
(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.releases.ReleasesApp', {
        extend: 'Rally.apps.common.TimeBoxesGridBoardApp',

        modelNames: ['Release'],
        statePrefix: 'release',

        startDateEmptyText: 'Select Start Date',
        startDateFieldName: 'ReleaseStartDate',
        endDateEmptyText: 'Select Release Date',
        endDateFieldName: 'ReleaseDate'
    });
})();
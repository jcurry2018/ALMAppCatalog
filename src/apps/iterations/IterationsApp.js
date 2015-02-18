(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.iterations.IterationsApp', {
        extend: 'Rally.apps.common.TimeBoxesGridBoardApp',

        modelNames: ['iteration'],
        statePrefix: 'iteration',

        startDateEmptyText: 'Select Start Date',
        startDateFieldName: 'StartDate',
        endDateEmptyText: 'Select End Date',
        endDateFieldName: 'EndDate'
    });
})();
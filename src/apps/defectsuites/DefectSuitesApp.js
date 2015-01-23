(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.defectsuites.DefectSuitesApp', {
        extend: 'Rally.app.GridBoardApp',

        columnNames: ['DisplayColor','Name','State','Priority','Severity','Owner'],
        enableXmlExport: true,
        modelNames: ['DefectSuite'],
        statePrefix: 'defectsuites'
    });
})();
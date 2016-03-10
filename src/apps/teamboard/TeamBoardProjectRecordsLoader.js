(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.TeamBoardProjectRecordsLoader', {
        requires: [
            'Rally.data.wsapi.Filter',
            'Rally.data.wsapi.Store'
        ],
        singleton: true,

        load: function(teamOids, callback, scope){
            return Ext.create('Rally.data.wsapi.Store', {
                autoLoad: {
                    callback: callback,
                    scope: scope
                },
                filters: Rally.data.wsapi.Filter.or(Ext.Array.map(teamOids ? teamOids.toString().split(',') : [Rally.environment.getContext().getProject().ObjectID], function(teamOid) {
                    return {
                        property: 'ObjectID',
                        operator: '=',
                        value: teamOid
                    };
                })),
                model: Ext.identityFn('Project'),
                sorters: ['Name']
            });
        }
    });
})();
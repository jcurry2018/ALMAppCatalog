(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.TeamBoardProjectRecordsLoader', {
        requires: [
            'Rally.data.wsapi.Filter',
            'Rally.data.wsapi.Store'
        ],
        singleton: true,

        load: function(teamOids, callback, scope){
            var config = {
                autoLoad: {
                    callback: callback,
                    scope: scope
                },
                model: Ext.identityFn('Project'),
                sorters: ['Name']
            };

            if(teamOids){
                config.filters = Rally.data.wsapi.Filter.or(Ext.Array.map(teamOids.toString().split(','), function(teamOid) {
                    return {
                        property: 'ObjectID',
                        operator: '=',
                        value: teamOid
                    };
                }));
            }else{
                config.pageSize = 10;
            }

            return Ext.create('Rally.data.wsapi.Store', config);
        }
    });

})();
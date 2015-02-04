(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.backlog.BacklogApp', {
        extend: 'Rally.app.GridBoardApp',
        columnNames: ['FormattedID', 'Name', 'PlanEstimate', 'Priority', 'Owner'],
        requires: ['Rally.data.wsapi.Filter'],
        modelNames: ['hierarchicalrequirement', 'defect', 'defectsuite'],
        statePrefix: 'backlog',

        getPermanentFilters: function () {
            return [
                { property: 'Release', operator: '=', value: null },
                { property: 'Iteration', operator: '=', value: null },
                Rally.data.wsapi.Filter.or([
                    Rally.data.wsapi.Filter.and([
                        { property: 'State', operator: '!=', value: 'Closed' },
                        { property: 'TypeDefOid', operator: '=', value: this._getTypeDefOidFor('defect') }
                    ]),
                    Rally.data.wsapi.Filter.and([
                        { property: 'DirectChildrenCount', operator: '=', value: '0' },
                        { property: 'TypeDefOid', operator: '=', value: this._getTypeDefOidFor('hierarchicalrequirement') }
                    ]),
                    { property: 'TypeDefOid', operator: '=', value: this._getTypeDefOidFor('defectsuite') }
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
(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.backlog.BacklogApp', {
        extend: 'Rally.app.GridBoardApp',
        alias: 'widget.backlogapp',
        columnNames: ['FormattedID', 'Name', 'PlanEstimate', 'Priority', 'Owner'],
        requires: ['Rally.data.wsapi.Filter'],
        modelNames: ['hierarchicalrequirement', 'defect', 'defectsuite'],
        statePrefix: 'backlog',

        getPermanentFilters: function (types) {
            types = (types === undefined ? ['hierarchicalrequirement', 'defect', 'defectSuite'] : types);

            var typeCriteria = [];
            if (_.contains(types, 'defect')) {
                typeCriteria.push(Rally.data.wsapi.Filter.and([
                    { property: 'State', operator: '!=', value: 'Closed' },
                    { property: 'TypeDefOid', operator: '=', value: this._getModelFor('defect').typeDefOid }
                ]));
            }
            if (_.contains(types, 'hierarchicalrequirement')) {
                typeCriteria.push(Rally.data.wsapi.Filter.and([
                    { property: 'DirectChildrenCount', operator: '=', value: 0 },
                    { property: 'TypeDefOid', operator: '=', value: this._getModelFor('hierarchicalrequirement').typeDefOid }
                ]));
            }

            var defectSuiteModel = this._getModelFor('defectsuite');
            return [
                Rally.data.wsapi.Filter.and([
                    { property: 'Release', operator: '=', value: null },
                    { property: 'Iteration', operator: '=', value: null }
                ]),
                Rally.data.wsapi.Filter.or(typeCriteria.concat(defectSuiteModel ? [{ property: 'TypeDefOid', operator: '=', value: defectSuiteModel.typeDefOid }] : []))
            ];
        },

        getGridConfig: function () {
            return _.merge(this.callParent(arguments), {
                inlineAddConfig: {
                    listeners: {
                        beforeeditorshow: function (addNewCmp, params) {
                            params.Iteration = 'u'; // explicitly set iteration to unscheduled so it doesn't default to current iteration on TPS editor.
                        }
                    }
                }
            });
        },

        getGridStoreConfig: function () {
            return {
                enableHierarchy: false
            };
        },

        getGridBoardCustomFilterControlConfig: function() {
            return {
                showOwnerFilter: false,
                showIdFilter: true,
                idFilterConfig:{
                    stateful: true,
                    stateId: this.getScopedStateId('backlog-id-filter'),
                    storeConfig:{
                        autoLoad: true,
                        pageSize: 25,
                        fetch: ['FormattedID', '_refObjectName'],
                        filters: this.getPermanentFilters()
                    }
                }
            };
        },

        _getModelFor: function(type) {
            return _.find(this.models, { typePath: type });
        },

        onFilterTypesChange: function(types) {
            this.gridboard.gridConfig.storeConfig.filters = this.getPermanentFilters(types);
        }
    });
})();
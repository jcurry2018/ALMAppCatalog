(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.BacklogBoardColumn', {
        extend: 'Rally.apps.roadmapplanningboard.PlanningBoardColumn',
        alias: 'widget.backlogplanningcolumn',

        requires: ['Rally.ui.SearchField'],

        config: {
            /**
             * @cfg {Rally.data.Store}
             * A store that contains all plans for this app - it is used to filter out features found in plans
             */
            planStore: null,

            columnHeaderConfig: {
                headerTpl: 'Backlog'
            }
        },

        constructor: function (config) {
            this.mergeConfig(config);
            this._createBaseFilter();

            this.callParent([this.config]);
        },

        drawHeader: function () {
            this.callParent(arguments);

            this.getColumnHeader().add({
                xtype: 'rallysearchfield',
                listeners: {
                    search: this._searchBacklog,
                    scope: this
                }
            });
        },

        getColumnIdentifier: function () {
            return "roadmapplanningboard.backlog.column";
        },

        _getAllPlanFeatures: function () {
            return _.reduce(this.planStore.data.items, function (result, plan) {
                return result.concat(plan.get('features'));
            }, []);
        },

        isMatchingRecord: function (featureRecord) {
            var recordId = featureRecord.get('_refObjectUUID'),
                found = _.find(this._getAllPlanFeatures(), { id: recordId });
            return !found;
        },

        getStoreFilter: function (model) {
            var storeFilter = this.baseFilter;

            if (this.filters) {
                storeFilter = _.reduce(this.filters, function (result, filter) {
                    return result ? result.and(filter) : filter;
                }, storeFilter);
            }

            return storeFilter;
        },

        _searchBacklog: function (cmp, value) {
            if (this.storeConfig.search !== value) {
                this.refresh({
                    storeConfig: {
                        search: value ? Ext.String.trim(value) : ""
                    }
                });
            }
        },

        _createBaseFilter: function () {
            this.baseFilter = new Rally.data.QueryFilter({
                property: 'ActualEndDate',
                operator: '=',
                value: 'null'
            });
        }
    });

})();

(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.BacklogBoardColumn', {
        extend: 'Rally.apps.roadmapplanningboard.PlanningBoardColumn',
        alias: 'widget.backlogplanningcolumn',

        config: {
            /**
             * @cfg {Rally.data.Store}
             * A store that contains all plans for this app - it is used to filter out features found in plans
             */
            planStore: null,

            filterable: true,
            columnHeaderConfig: {
                headerTpl: 'Backlog'
            },
            baseFilter: {
                property: 'ActualEndDate',
                operator: '=',
                value: 'null'
            },
            enableAutoPaging: true
        },

        getColumnIdentifier: function () {
            return "roadmapplanningboard.backlog.column";
        },

        _getAllPlanFeatures: function () {
            return _.reduce (this.planStore.data.items, function (result, plan) {
                return result.concat(plan.get('features'));
            }, []);
        },

        isMatchingRecord: function (featureRecord) {
            var found = _.find(this._getAllPlanFeatures(), function (feature) {
                return featureRecord.getId().toString() === feature.id;
            }, this);
            return !found;
        },

        getAllFetchFields: function () {
            return ['true'];
        }
    });

})();

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
            }
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
            var recordId = featureRecord.get('_refObjectUUID'),
                found = _.find(this._getAllPlanFeatures(), { id: recordId });
            return !found;
        }
    });

})();

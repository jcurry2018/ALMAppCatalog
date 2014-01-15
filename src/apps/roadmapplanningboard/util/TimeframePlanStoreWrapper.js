(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper', {
        config: {
            timeframeStore: null,
            planStore: null
        },

        constructor: function (config) {
            this.initConfig(config);
        },

        getTimeframeAndPlanRecords: function () {
            var _this = this;
            var records = _.map(this.timeframeStore.data.items, function(timeframe){
                return {
                    timeframe: timeframe,
                    plan: _this._getPlanForTimeframe(timeframe)
                };
            });

            return _.filter(records, function (record){
                return !!record.plan;
            });
        },

        _getPlanForTimeframe: function (timeframe) {
            return this.planStore.getAt(this.planStore.findBy(function (record) {
                return record.get('timeframe').id === timeframe.getId();
            }));
        }
    });
}).call(this);
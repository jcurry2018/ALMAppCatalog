(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper', {
        inject: ['planStore', 'timeframeStore'],

        config: {
            roadmap: null,
            timeline: null,
            requester: null
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

        load: function () {
            return Deft.Promise.all([
                this._loadPlanStore(),
                this._loadTimeframeStore()
            ]);
        },

        _getPlanForTimeframe: function (timeframe) {
            return this.planStore.getAt(this.planStore.findBy(function (record) {
                return record.get('timeframe').id === timeframe.getId();
            }));
        },

        _loadPlanStore: function () {
            return this.planStore.load({
                params: {
                    roadmap: {
                        id: this.roadmap.getId()
                    }
                },
                requester: this.requester,
                storeServiceName: 'Planning'
            });
        },

        _loadTimeframeStore: function () {
            return this.timeframeStore.load({
                params: {
                    timeline: {
                        id: this.timeline.getId()
                    }
                },
                requester: this.requester,
                storeServiceName: 'Timeline'
            });
        }
    });
}).call(this);
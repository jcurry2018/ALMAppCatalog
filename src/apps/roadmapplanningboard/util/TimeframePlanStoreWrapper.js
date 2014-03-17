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
            this.timeframeStore.on('update', this._timeframeUpdated, this);
        },

        getTimeframeAndPlanRecords: function () {
            var _this = this;
            var records = _.map(this.timeframeStore.data.items, function(timeframe){
                return {
                    timeframe: timeframe,
                    plan: _this._getPlanForTimeFrameAndSyncName(timeframe)
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

        deletePlan: function (planRecord) {
            var deferred = new Deft.Deferred();

            planRecord.destroy({
                success: function () {
                    deferred.resolve();
                },
                failure: function () {
                    deferred.reject('Failed to delete plan record');
                }
            });

            return deferred.promise;
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
        },

        _timeframeUpdated: function(store, record, operation, modifiedFieldNames, eOpts) {
            if (operation === 'edit' && _.contains(modifiedFieldNames, 'name')) {
                this._getPlanForTimeFrameAndSyncName(record);
            }
        },

        _getPlanForTimeFrameAndSyncName: function (timeframe) {
            var plan = this._getPlanForTimeframe(timeframe);
            var timeframName = timeframe.get('name');

            if (plan && plan.get('name') !== timeframName) {
                plan.set('name', timeframName);
                plan.save();
            }

            return plan;
        }
    });
}).call(this);
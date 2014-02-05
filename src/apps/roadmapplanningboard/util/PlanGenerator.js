(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.util.PlanGenerator', {
        requires: [
            'Rally.apps.roadmapplanningboard.AppModelFactory',
            'Rally.apps.roadmapplanningboard.util.NextDateRangeGenerator'
        ],

        inject: ['timeframeStore', 'planStore', 'nextDateRangeGenerator'],

        config: {
            timeframePlanStoreWrapper: null,
            roadmap: null
        },

        constructor: function (config) {
            this.initConfig(config);
        },

        createPlanWithTimeframe: function () {
            var lastRecord = _.last(this.timeframePlanStoreWrapper.getTimeframeAndPlanRecords());

            return Deft.promise.Chain.pipeline([this._createTimeframe, this._createPlan], this, lastRecord.timeframe);
        },

        _createTimeframe: function (oldTimeframeRecord) {
            var deferred = Ext.create('Deft.Deferred');

            _.first(this.timeframePlanStoreWrapper.timeframeStore.add({
                name: "New Timeframe",
                startDate: this.nextDateRangeGenerator.getNextStartDate(oldTimeframeRecord.get('endDate')),
                endDate: this.nextDateRangeGenerator.getNextEndDate(oldTimeframeRecord.get('startDate'), oldTimeframeRecord.get('endDate')),
                timeline: oldTimeframeRecord.get('timeline')
            })).save({

                success: function(record, operation) {
                    deferred.resolve(record);
                },

                failure: function(record, operation) {
                    deferred.reject(operation.error.status + ' ' + operation.error.statusText);
                }
            });

            return deferred;
        },

        _createPlan: function (timeframeRecord) {
            var deferred = Ext.create('Deft.Deferred');

            _.first(this.timeframePlanStoreWrapper.planStore.add({
                name: 'New Plan',
                theme: '',
                roadmap: {id: this.roadmap.getId()}, // Turn the roadmap into a JSON into a JSON object in order correctly match the url pattern in the Plan model proxy.
                timeframe: timeframeRecord,
                lowCapacity: 0,
                highCapacity: 0
            })).save({
                success: function (record, operation) {
                    deferred.resolve({planRecord: record, timeframeRecord: timeframeRecord});
                },
                failure: function (record, operation) {
                    deferred.reject(operation.error.status + ' ' + operation.error.statusText);
                },
                scope: this
            });

            return deferred;
        }
    });
}).call(this);
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

        createPlanWithTimeframe: function (options) {
            options = options || {};

            var lastRecordWithAPlan = _.last(this.timeframePlanStoreWrapper.getTimeframeAndPlanRecords());
            var lastTimeframeRecord = lastRecordWithAPlan ? lastRecordWithAPlan.timeframe : this.timeframePlanStoreWrapper.timeframeStore.last();

            var timeframeData = {
                timeline: lastTimeframeRecord.get('timeline'),
                startDate: null,
                endDate: null
            };

            if (!options.resetDates && lastRecordWithAPlan) {
                timeframeData.startDate = lastTimeframeRecord.get('startDate');
                timeframeData.endDate = lastTimeframeRecord.get('endDate');
            }

            return Deft.promise.Chain.pipeline([this._createTimeframe, this._createPlan], this, timeframeData);
        },

        _createTimeframe: function (timeframeData) {
            var deferred = Ext.create('Deft.Deferred');

            _.first(this.timeframePlanStoreWrapper.timeframeStore.add({
                name: "New Timeframe",
                startDate: this.nextDateRangeGenerator.getNextStartDate(timeframeData.endDate),
                endDate: this.nextDateRangeGenerator.getNextEndDate(timeframeData.startDate, timeframeData.endDate),
                timeline: timeframeData.timeline
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
                name: timeframeRecord.get('name'),
                theme: '',
                roadmap: {id: this.roadmap.getId()}, // Turn the roadmap into a JSON into a JSON object in order correctly match the url pattern in the Plan model proxy.
                timeframe: timeframeRecord,
                features: [],
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
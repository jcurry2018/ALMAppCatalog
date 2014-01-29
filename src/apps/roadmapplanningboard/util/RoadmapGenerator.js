(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.util.RoadmapGenerator', {
        requires: [
            'Rally.apps.roadmapplanningboard.AppModelFactory',
            'Rally.apps.roadmapplanningboard.util.NextDateRangeGenerator'
        ],

        config: {
            roadmapStore: null,
            timelineStore: null,
            workspace: null
        },

        constructor: function (config) {
            this.initConfig(config);
        },

        createTimelineRoadmap: function () {
            return Deft.promise.Chain.pipeline([this.createTimeline, this.createRoadmap], this);
        },

        createRoadmap: function (timeline) {
            var timeframes = timeline.get('timeframes');
            if (!timeframes || !timeframes.length) {
                throw 'Timeline must contain timeframes';
            }
            var deferred = new Deft.Deferred();

            var roadmapRecord = _.first(this.roadmapStore.add({
                name: this.workspace.Name + ' Roadmap',
                plans: this._createPlansForNewRoadmap(timeframes)
            }));

            roadmapRecord.save({
                success: function (record, operation) {
                    deferred.resolve(record);
                },
                failure: function (record, operation) {
                    deferred.reject('Unable to create a new roadmap.');
                }
            });

            return deferred.promise;
        },
        
        createTimeline: function () {
            var deferred = new Deft.Deferred();

            var timelineRecord = _.first(this.timelineStore.add({
                name: this.workspace.Name + ' Timeline',
                timeframes: this._createTimeframesForNewTimeline()
            }));

            timelineRecord.save({
                success: function (record, operation) {
                    deferred.resolve(record);
                },
                failure: function (record, operation) {
                    deferred.reject('Unable to create a new timeline.');
                }
            });
    
            return deferred.promise;
        },

        _createPlansForNewRoadmap: function (timeframes) {
            var _this = this;

            return _.map(timeframes, function (timeframe) {
                return _this._createPlanForNewRoadmap('New Plan', timeframe);
            });
        },

        _createPlanForNewRoadmap: function(name, timeframe) {
            var planModel = Rally.apps.roadmapplanningboard.AppModelFactory.getPlanModel();

            return Ext.create(planModel, {
                name: name,
                theme: '',
                timeframe: timeframe,
                lowCapacity: 0,
                highCapacity: 0
            });
        },

        _createTimeframesForNewTimeline: function () {
            var dateGenerator = Rally.apps.roadmapplanningboard.util.NextDateRangeGenerator;

            return [
                this._createTimeframeForNewTimeline('New Timeframe', dateGenerator.getNextStartDate(), dateGenerator.getNextEndDate())
            ];
        },

        _createTimeframeForNewTimeline: function (name, startDate, endDate) {
            var timeframeModel = Rally.apps.roadmapplanningboard.AppModelFactory.getTimeframeModel();

            return Ext.create(timeframeModel, {
                name: name,
                startDate: startDate,
                endDate: endDate
            });
        }
    });
}).call(this);
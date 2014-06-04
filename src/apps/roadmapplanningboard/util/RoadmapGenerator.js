(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.util.RoadmapGenerator', {
        requires: [
            'Rally.apps.roadmapplanningboard.AppModelFactory',
            'Rally.apps.roadmapplanningboard.util.NextDateRangeGenerator'
        ],

        config: {
            timelineRoadmapStoreWrapper: null,
            workspace: null
        },

        constructor: function (config) {
            this.initConfig(config);
        },

        createCompleteRoadmapData: function () {
            var promiseOptions = {
                success: function () {
                    return {
                        roadmap: this.timelineRoadmapStoreWrapper.activeRoadmap(),
                        timeline: this.timelineRoadmapStoreWrapper.activeTimeline()
                    };
                },
                scope: this
            };

            var deferred = new Deft.Deferred();

            if(!this.timelineRoadmapStoreWrapper.hasTimeline() && this.timelineRoadmapStoreWrapper.hasRoadmap()) {
                deferred.reject('Cannot create a timeline when a roadmap already exists');
            } else if(!this.timelineRoadmapStoreWrapper.hasTimeline() && !this.timelineRoadmapStoreWrapper.hasRoadmap()) {
                return this._createTimelineRoadmap().then(promiseOptions);
            } else if (!this.timelineRoadmapStoreWrapper.hasRoadmap()) {
                return this._createRoadmap().then(promiseOptions);
            } else {
                deferred.resolve(promiseOptions);
            }

            return deferred.promise;
        },

        _createTimelineRoadmap: function () {
            return Deft.promise.Chain.pipeline([this._createTimeline, this._createRoadmap], this);
        },

        _createRoadmap: function () {
            var timeline = this.timelineRoadmapStoreWrapper.activeTimeline();
            var timeframes = timeline.get('timeframes');
            var deferred = new Deft.Deferred();

            if (!timeframes || !timeframes.length) {
                deferred.reject('Timeline must contain timeframes');
            } else {
                var roadmapRecord = _.first(this.timelineRoadmapStoreWrapper.roadmapStore.add({
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
            }

            return deferred.promise;
        },
        
        _createTimeline: function () {
            var deferred = new Deft.Deferred();

            var timelineRecord = _.first(this.timelineRoadmapStoreWrapper.timelineStore.add({
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
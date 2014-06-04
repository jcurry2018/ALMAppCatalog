(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.util.TimelineRoadmapStoreWrapper', {
        requires: ['Rally.apps.roadmapplanningboard.DeftInjector'],

        inject: ['timelineStore','roadmapStore'],

        config: {
            requester: null
        },

        constructor: function (config) {
            this.initConfig(config);
        },

        load: function () {
            return Deft.Promise.all([
                this.roadmapStore.load({requester: this.requester, storeServiceName: "Planning"}),
                this.timelineStore.load({requester: this.requester, storeServiceName: "Timeline"})
            ]).then(function (results){
                return {
                    roadmap: results[0].records[0],
                    timeline: results[1].records[0]
                };
            });
        },

        activeTimeline: function () {
            return this.timelineStore.first();
        },

        activeRoadmap: function () {
            return this.roadmapStore.first();
        },

        hasCompleteRoadmapData: function () {
            return this.hasTimeline() && this.hasRoadmap();
        },

        hasTimeline: function () {
            return this.timelineStore.count() > 0;
        },

        hasRoadmap: function () {
            return this.roadmapStore.count() > 0;
        }
    });
}).call(this);
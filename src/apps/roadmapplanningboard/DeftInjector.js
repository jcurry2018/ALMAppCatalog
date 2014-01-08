(function() {

    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.DeftInjector', {
        singleton: true,
        requires: [
            'Rally.data.Store',
            'Rally.apps.roadmapplanningboard.AppModelFactory',
            'Rally.apps.roadmapplanningboard.UuidMapper'
        ],
        loaded: false,

        init: function () {
            if (!this.loaded) {
                Deft.Injector.configure({
                    timelineStore: {
                        className: 'Rally.data.Store',
                        parameters: [{
                            model: Rally.apps.roadmapplanningboard.AppModelFactory.getTimelineModel()
                        }]
                    },
                    timeframeStore: {
                        className: 'Rally.data.Store',
                        parameters: [{
                            model: Rally.apps.roadmapplanningboard.AppModelFactory.getTimeframeModel()
                        }]
                    },
                    planStore: {
                        className: 'Rally.data.Store',
                        parameters: [{
                            model: Rally.apps.roadmapplanningboard.AppModelFactory.getPlanModel()
                        }]
                    },
                    roadmapStore: {
                        className: 'Rally.data.Store',
                        parameters: [{
                            model: Rally.apps.roadmapplanningboard.AppModelFactory.getRoadmapModel()
                        }]
                    },
                    preliminaryEstimateStore: {
                      className: 'Rally.data.wsapi.Store',
                      parameters: [{
                            model: 'PreliminaryEstimate'
                      }]
                    },
                    uuidMapper: {
                        className: 'Rally.apps.roadmapplanningboard.UuidMapper'
                    }
                });
            }
            this.loaded = true;
        }
    });
})();

(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardController', {
        requires: [
            'Rally.apps.roadmapplanningboard.DeftInjector',
            'Rally.data.util.PortfolioItemHelper',
            'Rally.apps.roadmapplanningboard.PlanningBoard',
            'Rally.apps.roadmapplanningboard.plugin.RoadmapScrollable',
            'Rally.ui.notify.Notifier',
            'Rally.ui.feedback.Feedback'
        ],

        feedback: null,
        cardboard: null,

        config: {
            listeners: null,
            context: null,
            containerConfig: {
                cls: 'roadmap-planning-container',
                height: '100%'
            },
            feedbackConfig: {
                feedbackDialogConfig: {
                    title: 'Feedback on Roadmap Planning Board',
                    subject: 'Roadmap Planning Board',
                    feedbackId: 'roadmapplanningboard'
                }
            }
        },

        constructor: function (config) {
            this.initConfig(config);
            this.context = this.context || Rally.environment.getContext();
        },

        createPlanningBoard: function () {
            this.container = Ext.create('Ext.container.Container', this.containerConfig);

            this.feedback = Ext.create('Rally.ui.feedback.Feedback', this.feedbackConfig);
            this.container.add(this.feedback);

            Rally.apps.roadmapplanningboard.DeftInjector.init();
            this.roadmapStore = Deft.Injector.resolve('roadmapStore');
            this.timelineStore = Deft.Injector.resolve('timelineStore');

            Ext.Ajax.on('requestexception', this._onRequestException, this);

            this._retrieveLowestLevelPI(function (record) {
                this.types = [record.get('TypePath')];

                var roadmapPromise = this.roadmapStore.load({requester: this, storeServiceName: "Planning"});
                var timelinePromise = this.timelineStore.load({requester: this, storeServiceName: "Timeline"});

                //should be able to get timeline and roadmap async, get some promises
                Deft.Promise.all([roadmapPromise, timelinePromise]).then({
                    success: function (results) {
                        var roadmap = results[0].records[0];
                        var timeline = results[1].records[0];
                        this._buildCardBoard.call(this, roadmap, timeline);
                    },
                    failure: function (operation) {
                        var service = operation.storeServiceName || 'External';
                        Rally.ui.notify.Notifier.showError({message: 'Failed to load app: ' + service + ' service data load issue'});
                    },
                    scope: this
                });
            });

            return this.container;
        },

        _onRequestException: function (connection, response, requestOptions) {
            var requester = requestOptions.operation && requestOptions.operation.requester;
            var el = this.container && this.container.getEl();

            if (requester === this && el) {
                el.mask('Roadmap planning is <strong>temporarily unavailable</strong>, please try again in a few minutes.', "roadmap-service-unavailable-error");
            }
        },

        _retrieveLowestLevelPI: function (callback) {
            Rally.data.util.PortfolioItemHelper.loadTypeOrDefault({
                defaultToLowest: true,
                success: callback,
                scope: this
            });
        },

        _buildCardBoard: function (roadmap, timeline) {
            if (roadmap && timeline) {
                this.cardboard = Ext.create('Rally.apps.roadmapplanningboard.PlanningBoard', {
                    roadmap: roadmap,
                    timeline: timeline,
                    isAdmin: this._isUserAdmin(),
                    types: this.types,
                    plugins: [
                        {
                            ptype: 'rallytimeframescrollablecardboard', timeframeColumnCount: 3
                        },
                        {
                            ptype: 'rallyfixedheadercardboard'
                        }
                    ],
                    listeners: {
                        load: this._onCardBoardLoad,
                        scope: this
                    }
                });
                this.container.add(this.cardboard);
            } else if (!roadmap) {
                Rally.ui.notify.Notifier.showError({message: 'No roadmap available'});
            } else {
                Rally.ui.notify.Notifier.showError({message: 'No timeline available'});
            }
        },

        _isUserAdmin: function () {
            var permissions = Rally.environment.getContext().getPermissions();
            var isAdmin = permissions.isSubscriptionAdmin();
            if (!isAdmin) {
                var workspace = this.getContext().getWorkspace();
                isAdmin = permissions.isWorkspaceAdmin(workspace._ref);
            }
            return isAdmin;
        },

        _onCardBoardLoad: function () {
            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this.container);
            }
        }
    });
})();

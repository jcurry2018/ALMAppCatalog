(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.apps.roadmapplanningboard.DeftInjector',
            'Rally.data.util.PortfolioItemHelper',
            'Rally.apps.roadmapplanningboard.PlanningBoard',
            'Rally.apps.roadmapplanningboard.plugin.RoadmapScrollable'
        ],
        cls: 'roadmapPlanningBoardApp',
        componentCls: 'app',
        cardboard: null,

        onRequestException: function (connection, response, requestOptions) {
            var requester = requestOptions.operation && requestOptions.operation.requester;
            if (requester && (requester === this || requester.up('rallyapp'))) {
                this.getEl().mask('Roadmap planning is <strong>temporarily unavailable</strong>, please try again in a few minutes.', "roadmap-service-unavailable-error");
            }
        },

        launch: function () {
            Rally.apps.roadmapplanningboard.DeftInjector.init();
            var roadmapStore = Deft.Injector.resolve('roadmapStore');

            var permissions = Rally.environment.getContext().getPermissions();
            var isAdmin = permissions.isSubscriptionAdmin();
            if (!isAdmin) {
                var workspace = this.getContext().getWorkspace();
                isAdmin = permissions.isWorkspaceAdmin(workspace._ref);
            }

            Ext.Ajax.on('requestexception', this.onRequestException, this);

            this._retrieveLowestLevelPI(function (record) {
                roadmapStore.load({callback: function (records, operation, success) {
                    if (success) {
                        this.cardboard = Ext.create('Rally.apps.roadmapplanningboard.PlanningBoard', {
                            roadmapId: roadmapStore.first() ? roadmapStore.first().getId() : undefined,
                            isAdmin: isAdmin,
                            types: [record.get('TypePath')],
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
                        this.add(this.cardboard);
                    }
                },
                    requester: this,
                    scope: this
                });
            });
        },

        _retrieveLowestLevelPI: function (callback) {
            Rally.data.util.PortfolioItemHelper.loadTypeOrDefault({
                defaultToLowest: true,
                success: callback,
                scope: this
            });
        },

        _onCardBoardLoad: function () {
            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this);
            }
        }
    });

})();

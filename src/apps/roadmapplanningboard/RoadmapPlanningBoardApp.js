(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.data.util.PortfolioItemHelper',
            'Rally.apps.roadmapplanningboard.SplashContainer',
            'Rally.ui.notify.Notifier',
            'Rally.apps.roadmapplanningboard.DeftInjector',
            'Rally.apps.roadmapplanningboard.PlanningGridBoard'
        ],
        cls: 'roadmapPlanningBoardApp',
        componentCls: 'app',

        config: {
            feedbackConfig: {
                feedbackDialogConfig: {
                    title: 'Feedback on Roadmap Planning Board',
                    subject: 'Roadmap Planning Board',
                    feedbackId: 'roadmapplanningboard'
                }
            },

            addNewConfig: {
                ignoredRequiredFields: ['Name', 'Project', 'ScheduleState', 'State']
            },

            /**
             * @cfg cardboardPlugins {Array}
             * Extra plugins that should be added to the cardboard
             */
            cardboardPlugins: [
                {
                    ptype: 'rallyfixedheadercardboard'
                }
            ]
        },

        launch: function () {
            Rally.apps.roadmapplanningboard.DeftInjector.init();

            this.roadmapStore = Deft.Injector.resolve('roadmapStore');
            this.timelineStore = Deft.Injector.resolve('timelineStore');

            Ext.Ajax.on('requestexception', this._onRequestException, this);

            this._retrievePITypes(function (records) {
                this.types = [records[0].get('TypePath')];
                this.typeNames = {
                    child: {
                        typePath: records[0].get('TypePath'),
                        name: records[0].get('Name')
                    }
                };

                if (records.length > 1) {
                    this.typeNames.parent = {
                        typePath: records[1].get('TypePath'),
                        name: records[1].get('Name')
                    };
                }

                var roadmapPromise = this.roadmapStore.load({requester: this, storeServiceName: "Planning"});
                var timelinePromise = this.timelineStore.load({requester: this, storeServiceName: "Timeline"});
                var preferencePromise = Rally.apps.roadmapplanningboard.SplashContainer.loadPreference();

                Deft.Promise.all([roadmapPromise, timelinePromise, preferencePromise]).then({
                    success: function (results) {
                        var roadmap = results[0].records[0];
                        var timeline = results[1].records[0];
                        var preference = results[2][Rally.apps.roadmapplanningboard.SplashContainer.PREFERENCE_NAME];
                        var loadCarousel = (!roadmap || !timeline || !preference);

                        if (loadCarousel) {
                            this.splash = this.add({
                                xtype: 'splashcontainer',
                                isAdmin: this._isUserAdmin(),
                                showGotIt: roadmap && timeline,
                                listeners: {
                                    gotit: function (event, cmp) {
                                        this.splash.destroy();
                                        this._buildGridBoard(roadmap, timeline);
                                    },
                                    scope: this
                                }
                            });
                        } else {
                            this._buildGridBoard(roadmap, timeline);
                        }

                        if (Rally.BrowserTest) {
                            Rally.BrowserTest.publishComponentReady(this);
                        }
                    },
                    failure: function (operation) {
                        var service = operation.storeServiceName || 'External';
                        Rally.ui.notify.Notifier.showError({message: 'Failed to load app: ' + service + ' service data load issue'});
                    },
                    scope: this
                });
            });
        },

        _retrievePITypes: function (callback) {
            Rally.data.util.PortfolioItemHelper.loadTypeOrDefault({
                defaultToLowest: true,
                loadAllTypes: true,
                success: callback,
                scope: this
            });
        },

        _buildGridBoard: function (roadmap, timeline) {
            if (roadmap && timeline) {
                this.add({
                    xtype: 'roadmapplanninggridboard',
                    itemId: 'gridboard',
                    context: this.getContext(),
                    timeline: timeline,
                    roadmap: roadmap,
                    isAdmin: this._isUserAdmin(),
                    typeNames: this.typeNames,
                    modelNames: this.types,
                    cardboardPlugins: this.cardboardPlugins,
                    height: this._computePanelContentAreaHeight()
                });
            } else if (!roadmap) {
                Rally.ui.notify.Notifier.showError({message: 'No roadmap available'});
            } else {
                Rally.ui.notify.Notifier.showError({message: 'No timeline available'});
            }
        },

        _computePanelContentAreaHeight: function () {
            if(this.getHeight()) {
                return this.getHeight();
            }

            var content = Ext.getBody().down('#content');
            if (!content && Rally.BrowserTest) {
                return Ext.getBody().down('#testDiv').getHeight();
            }
            return content.getHeight() - content.down('.page').getHeight();
        },

        _onRequestException: function (connection, response, requestOptions) {
            var requester = requestOptions.operation && requestOptions.operation.requester;
            var el = this.getEl();

            if (requester === this && el) {
                this.setHeight(this._computePanelContentAreaHeight());
                el.mask('Roadmap planning is <strong>temporarily unavailable</strong>, please try again in a few minutes.', "roadmap-service-unavailable-error");
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
        }
    });
})();

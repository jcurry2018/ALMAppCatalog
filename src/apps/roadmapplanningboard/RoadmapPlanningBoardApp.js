
(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.data.util.PortfolioItemHelper',
            'Rally.apps.roadmapplanningboard.SplashContainer',
            'Rally.ui.notify.Notifier',
            'Rally.apps.roadmapplanningboard.DeftInjector',
            'Rally.apps.roadmapplanningboard.PlanningGridBoard',
            'Rally.apps.roadmapplanningboard.util.TimelineRoadmapStoreWrapper',
            'Rally.apps.roadmapplanningboard.util.UserPermissions',
            'Rally.apps.roadmapplanningboard.util.RoadmapGenerator',
            'Rally.clientmetrics.ClientMetricsRecordable',
            'Rally.util.BrowserValidation'
        ],
        cls: 'roadmap-planning-board',
        autoScroll: false,
        mixins: [
            'Rally.clientmetrics.ClientMetricsRecordable'
        ],
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
            }
        },

        launch: function() {
            Rally.apps.roadmapplanningboard.DeftInjector.init();

            // Assume global context if it wasn't passed
            this.context = this.context || Rally.environment.getContext();

            this.timelineRoadmapStoreWrapper = Ext.create('Rally.apps.roadmapplanningboard.util.TimelineRoadmapStoreWrapper', {
                requester: this
            });

            var userPermissions = Ext.create('Rally.apps.roadmapplanningboard.util.UserPermissions', {
                workspace: this.context.getWorkspace(),
                permissions: Rally.environment.getContext().getPermissions()
            });

            this.isAdmin = userPermissions.isUserAdmin();

            this.lsCacheProvider = Ext.create('Rally.state.LSCacheProvider', {});

            this.browserCheck();

            this.mon(Ext.Ajax, 'requestexception', this._onRequestException, this);

            this._retrievePITypes(function(records) {
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

                var preferencePromise = Rally.apps.roadmapplanningboard.SplashContainer.loadPreference().then({
                    success: function(result) {
                        this.alreadyGotIt = result[Rally.apps.roadmapplanningboard.SplashContainer.PREFERENCE_NAME];
                    },
                    scope: this
                });

                Deft.Promise.all([this.timelineRoadmapStoreWrapper.load(), preferencePromise]).then({
                    success: function(results) {
                        var roadmapDataExists = this.timelineRoadmapStoreWrapper.hasCompleteRoadmapData();
                        if (!roadmapDataExists || !this.alreadyGotIt) {
                            this.splash = this.add({
                                xtype: 'splashcontainer',
                                showGetStarted: this.isAdmin && !roadmapDataExists,
                                showGotIt: roadmapDataExists,
                                listeners: {
                                    gotit: function() {
                                        this.splash.destroy();
                                        this._buildGridBoard();
                                    },
                                    getstarted: function() {
                                        this.splash.destroy();
                                        this._createRoadmapData().then({
                                            success: function() {
                                                this._buildGridBoard({
                                                    firstLoad: true
                                                });
                                            },
                                            failure: function(error) {
                                                this._displayError('Unable to create roadmap data: ' + error);
                                            },
                                            scope: this
                                        });
                                    },
                                    scope: this
                                }
                            });
                        } else {
                            this._buildGridBoard();
                        }

                        if (Rally.BrowserTest) {
                            Rally.BrowserTest.publishComponentReady(this);
                        }
                    },
                    failure: function(operation) {
                        var service = operation.storeServiceName || 'External';
                        this._displayError('Failed to load app: ' + service + ' service data load issue');
                    },
                    scope: this
                });
            });
        },

        _getBrowserPrefValue: function () {
            return this.lsCacheProvider.get('RoadmapBrowserCheckPreference', null);
        },

        _setBrowserPrefValue: function() {
            return this.lsCacheProvider.set('RoadmapBrowserCheckPreference', true);
        },

        browserCheck: function() {
            var browserInfo = Rally.util.BrowserValidation.getCurrentBrowserInfo();

            if (!this._getBrowserPrefValue()) {
                this._setBrowserPrefValue();

                if (!Rally.util.BrowserValidation.isSupported(browserInfo)) {
                    Rally.ui.notify.Notifier.showError({
                        allowHTML: true,
                        message: browserInfo.displayName + " " + browserInfo.version + ' is not supported. For a better experience, please use a <a target="_blank" href="https://help.rallydev.com/supported-web-browsers">supported browser</a>'
                    });
                }
            }
        },

        _displayError: function(message) {
            Rally.ui.notify.Notifier.showError({message: message});
        },

        _createRoadmapData: function() {
            var roadmapGenerator = Ext.create('Rally.apps.roadmapplanningboard.util.RoadmapGenerator', {
                timelineRoadmapStoreWrapper: this.timelineRoadmapStoreWrapper,
                workspace: this.context.getWorkspace()
            });

            return roadmapGenerator.createCompleteRoadmapData();
        },

        _retrievePITypes: function(callback) {
            Rally.data.util.PortfolioItemHelper.loadTypeOrDefault({
                defaultToLowest: true,
                loadAllTypes: true,
                success: callback,
                scope: this
            });
        },

        _buildGridBoard: function(config) {
            config = config || {};

            var boardConfig = Ext.merge({
                xtype: 'roadmapplanninggridboard',
                itemId: 'gridboard',
                context: this.context,
                timeline: this.timelineRoadmapStoreWrapper.activeTimeline(),
                roadmap: this.timelineRoadmapStoreWrapper.activeRoadmap(),
                isAdmin: this.isAdmin,
                typeNames: this.typeNames,
                modelNames: this.types,
                shouldDestroyTreeStore: this.getContext().isFeatureEnabled('S73617_GRIDBOARD_SHOULD_DESTROY_TREESTORE'),
                listeners: {
                    load: this._onLoad,
                    scope: this
                },
                height: this.getHeight()
            }, config);

            this.add(boardConfig);
        },

        setHeight: function(height) {
            this.callParent(arguments);
            if(this.down('#gridboard')) {
                this.down('#gridboard').setHeight(height);
            }
        },

        _onRequestException: function(connection, response, requestOptions) {
            var requester = requestOptions.operation && requestOptions.operation.requester;
            var el = this.getEl();

            if (requester === this && el) {
                el.mask('Roadmap planning is <strong>temporarily unavailable</strong>, please try again in a few minutes.', "roadmap-service-unavailable-error");
            }
        },

        _onLoad: function() {
            this.recordComponentReady();
        }
    });
})();

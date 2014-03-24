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
            'Rally.clientmetrics.ClientMetricsRecordable'
        ],
        cls: 'roadmapPlanningBoardApp',
        componentCls: 'app',
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

            this.browserCheck();

            Ext.Ajax.on('requestexception', this._onRequestException, this);

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

        browserCheck: function() {
            var minBrowserVersion = {
                "Chrome": {displayName: "Chrome", minVersion: 32},
                "Firefox": {displayName: "Firefox", minVersion: 27},
                "Mac_Safari": {displayName: "Safari", minVersion: 6},
                "Win_Safari": {displayName: "Safari", minVersion: 4},
                "MSIE": {displayName: "IE", minVersion: 9}
            };
            var name;
            var version;
            var userAgent = window.navigator.userAgent;
            var browser = userAgent.match(/(Chrome|Firefox)\/\d+/g) || userAgent.match(/Safari\/\d+/g) || userAgent.match(/MSIE \d+/g);
            if (browser && browser.length > 0) {
                browser = browser[0];
                name = browser.match(/[a-zA-Z]+/g)[0];
                if (name === "Safari") {
                    name = userAgent.match(/Macintosh;/g) ? 'Mac_Safari' : 'Win_Safari';
                    version = userAgent.match(/Version\/\d+/g)[0].match(/\d+/g)[0];
                } else {
                    version = browser.match(/\d+/g)[0];
                }
                browser = minBrowserVersion[name];
            }
            if ((name && version < browser.minVersion)) {
                Rally.ui.notify.Notifier.showError({
                    allowHTML: true,
                    message: browser.displayName + " " + version + ' is not supported. For a better experience, please use a <a target="_blank" href="https://help.rallydev.com/supported-web-browsers">supported browser</a>'
                });
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
                cardboardPlugins: this.cardboardPlugins,
                listeners: {
                    load: this._onLoad,
                    scope: this
                }
            }, config);

            if (!this.getHeight()) {
                boardConfig.height = this._computeFullPagePanelContentAreaHeight();
            }

            this.add(boardConfig);
        },

        _computeFullPagePanelContentAreaHeight: function() {
            var content = Ext.getBody().down('#content');
            if (!content && Rally.BrowserTest) {
                return Ext.getBody().down('#testDiv').getHeight();
            }
            return content.getHeight() - content.down('.page').getHeight();
        },

        _onRequestException: function(connection, response, requestOptions) {
            var requester = requestOptions.operation && requestOptions.operation.requester;
            var el = this.getEl();

            if (requester === this && el) {
                this.setHeight(this._computeFullPagePanelContentAreaHeight());
                el.mask('Roadmap planning is <strong>temporarily unavailable</strong>, please try again in a few minutes.', "roadmap-service-unavailable-error");
            }
        },

        _onLoad: function() {
            this.recordComponentReady();
        }
    });
})();

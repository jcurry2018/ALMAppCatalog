(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardContainer', {
        extend: 'Ext.container.Container',
        requires: [
            'Rally.data.util.PortfolioItemHelper',
            'Rally.ui.notify.Notifier',
            'Rally.apps.roadmapplanningboard.DeftInjector',
            'Rally.apps.roadmapplanningboard.PlanningGridBoard'
        ],
        cls: 'roadmap-planning-container',

        config: {
            listeners: null,
            context: null,
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
            cardboardPlugins: []
        },

        items: [
            {
                xtype: 'container',
                itemId: 'gridboard'
            }
        ],

        constructor: function (config) {
            this.callParent(arguments);
            this.initConfig(config);
            this.context = this.context || Rally.environment.getContext();

            Rally.apps.roadmapplanningboard.DeftInjector.init();

            this.roadmapStore = Deft.Injector.resolve('roadmapStore');
            this.timelineStore = Deft.Injector.resolve('timelineStore');

            Ext.Ajax.on('requestexception', this._onRequestException, this);

            this._retrieveLowestLevelPI(function (record) {
                this.types = [record.get('TypePath')];
                this.typeName = record.get('Name');

                var roadmapPromise = this.roadmapStore.load({requester: this, storeServiceName: "Planning"});
                var timelinePromise = this.timelineStore.load({requester: this, storeServiceName: "Timeline"});

                Deft.Promise.all([roadmapPromise, timelinePromise]).then({
                    success: function (results) {
                        var roadmap = results[0].records[0];
                        var timeline = results[1].records[0];

                        this.gridboard = this._buildGridBoard(roadmap, timeline);

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

        _buildGridBoard: function (roadmap, timeline) {
            if (roadmap && timeline) {
                return this.down('#gridboard').add({
                    xtype: 'roadmapplanninggridboard',
                    context: this.getContext(),
                    timeline: timeline,
                    roadmap: roadmap,
                    typeName: this.typeName,
                    modelNames: this.types,
                    cardboardPlugins: this.cardboardPlugins,
                    height: this._getGridboardHeight()
                });
            } else if (!roadmap) {
                Rally.ui.notify.Notifier.showError({message: 'No roadmap available'});
            } else {
                Rally.ui.notify.Notifier.showError({message: 'No timeline available'});
            }
        },

        _getGridboardHeight: function () {
            if (this.getEl().getHeight()) {
                return this.getEl().getHeight();
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

        destroy: function () {
            if (this.gridboard) {
                this.gridboard.destroy();
            }

            this.callParent(arguments);
        }
    });
})();

(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.data.util.PortfolioItemHelper',
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

                this.gridboard = this.down('#gridboard');
                var roadmapPromise = this.roadmapStore.load({requester: this, storeServiceName: "Planning"});
                var timelinePromise = this.timelineStore.load({requester: this, storeServiceName: "Timeline"});

                Deft.Promise.all([roadmapPromise, timelinePromise]).then({
                    success: function (results) {
                        var roadmap = results[0].records[0];
                        var timeline = results[1].records[0];

                        this._buildGridBoard(roadmap, timeline);

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
            var height = this.getHeight() || this._computePanelContentAreaHeight();
            if (roadmap && timeline) {
                this.add({
                    xtype: 'roadmapplanninggridboard',
                    context: this.getContext(),
                    timeline: timeline,
                    roadmap: roadmap,
                    typeNames: this.typeNames,
                    modelNames: this.types,
                    cardboardPlugins: this.cardboardPlugins,
                    height: height
                });
            } else if (!roadmap) {
                Rally.ui.notify.Notifier.showError({message: 'No roadmap available'});
            } else {
                Rally.ui.notify.Notifier.showError({message: 'No timeline available'});
            }
        },

        _computePanelContentAreaHeight: function () {
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
//                this.gridboard.setHeight(this._computePanelContentAreaHeight());
                this.setHeight(this._computePanelContentAreaHeight());
                el.mask('Roadmap planning is <strong>temporarily unavailable</strong>, please try again in a few minutes.', "roadmap-service-unavailable-error");
            }
        }
    });
})();

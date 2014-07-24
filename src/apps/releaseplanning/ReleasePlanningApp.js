(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.releaseplanning.ReleasePlanningApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.data.util.PortfolioItemHelper',
            'Rally.ui.gridboard.planning.TimeboxGridBoard',
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl'
        ],

        launch: function() {
            Rally.data.util.PortfolioItemHelper.loadTypeOrDefault({
                defaultToLowest: true,
                success: function (piTypeDef) {
                    this._buildGridBoard(piTypeDef.get('TypePath'));
                },
                scope: this
            });
        },

        _buildGridBoard: function (piTypePath) {
            this.gridboard = this.add({
                xtype: 'rallytimeboxgridboard',
                cardBoardConfig: {
                    columnConfig: {
                        columnStatusConfig: {
                            pointField: 'PreliminaryEstimate.Value'
                        }
                    },
                    listeners: {
                        filter: this._onBoardFilter,
                        filtercomplete: this._onBoardFilterComplete,
                        scope: this
                    }
                },
                context: this.getContext(),
                endDateField: 'ReleaseDate',
                listeners: {
                    load: this._onLoad,
                    toggle: this._publishContentUpdated,
                    recordupdate: this._publishContentUpdatedNoDashboardLayout,
                    recordcreate: this._publishContentUpdatedNoDashboardLayout,
                    preferencesaved: this._publishPreferenceSaved,
                    scope: this
                },
                modelNames: [piTypePath],
                plugins: [
                    {
                        ptype: 'rallygridboardaddnew',
                        rankScope: 'BACKLOG'
                    },
                    {
                        ptype: 'rallygridboardcustomfiltercontrol',
                        filterChildren: false,
                        filterControlConfig: {
                            blackListFields: [
                                'DirectChildrenCount',
                                'DisplayColor',
                                'DragAndDropRank',
                                'Iteration',
                                'TestCase',
                                'TestCaseResult',
                                'VersionId',
                                'PortfolioItemType',
                                'Release'
                            ],
                            whiteListFields: [
                                'Tags'
                            ],
                            margin: '3 10 3 0',
                            modelNames: [piTypePath],
                            stateId: this.getContext().getScopedStateId('release-planning-custom-filter-button'),
                            cls: 'small gridboard-filter-control',
                            context: this.getContext(),
                            stateful: true
                        }
                    },
                    {
                        ptype: 'rallygridboardfieldpicker',
                        boardFieldBlackList: [
                            'ObjectID',
                            'Description',
                            'DisplayColor',
                            'FormattedID',
                            'Name',
                            'Notes',
                            'Ready',
                            'AcceptedLeafStoryCount',
                            'AcceptedLeafStoryPlanEstimateTotal',
                            'DirectChildrenCount',
                            'LeafStoryCount',
                            'LeafStoryPlanEstimateTotal',
                            'Rank',
                            'DragAndDropRank',
                            'UnEstimatedLeafStoryCount',
                            'CreationDate',
                            'Subscription',
                            'Workspace',
                            'Changesets',
                            'Discussion',
                            'LastUpdateDate',
                            'Owner',
                            'PortfolioItemType'
                        ],
                        boardFieldDefaults: ['PreliminaryEstimate', 'UserStories'],
                        headerPosition: 'left'
                    }
                ],
                startDateField: 'ReleaseStartDate',
                timeboxType: 'Release',
                useFilterCollection: false
            });
        },

        _onLoad: function() {
            this._publishContentUpdated();
            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this);
            }
        },

        _onBoardFilter: function() {
            this.setLoading(true);
        },

        _onBoardFilterComplete: function() {
            this.setLoading(false);
        },

        _publishContentUpdated: function() {
            this.fireEvent('contentupdated');
        },

        _publishContentUpdatedNoDashboardLayout: function() {
            this.fireEvent('contentupdated', {dashboardLayout: false});
        },

        _publishPreferenceSaved: function(record) {
            this.fireEvent('preferencesaved', record);
        }
    });
})();

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
            var boardFieldBlacklist =  [
                    'AcceptedLeafStoryCount',
                    'AcceptedLeafStoryPlanEstimateTotal',
                    'DirectChildrenCount',
                    'LeafStoryCount',
                    'LeafStoryPlanEstimateTotal',
                    'LastUpdateDate',
                    'State',
                    'UnEstimatedLeafStoryCount'
                ],
                context = this.getContext();

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
                context: context,
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
                        rankScope: 'BACKLOG',
                        addNewControlConfig: {
                            stateful: true,
                            stateId: context.getScopedStateId('release-planning-add-new')
                        }
                    },
                    {
                        ptype: 'rallygridboardcustomfiltercontrol',
                        filterChildren: false,
                        filterControlConfig: {
                            margin: '3 9 3 30',
                            blackListFields: ['PortfolioItemType', 'Release'],
                            whiteListFields: ['Milestones'],
                            modelNames: [piTypePath],
                            stateful: true,
                            stateId: context.getScopedStateId('release-planning-custom-filter-button')
                        },
                        showOwnerFilter: true,
                        ownerFilterControlConfig: {
                            stateful: true,
                            stateId: context.getScopedStateId('release-planning-owner-filter')
                        }
                    },
                    {
                        ptype: 'rallygridboardfieldpicker',
                        boardFieldBlackList: boardFieldBlacklist,
                        boardFieldDefaults: this._getDefaultFields(),
                        headerPosition: 'left'
                    }
                ],
                startDateField: 'ReleaseStartDate',
                timeboxType: 'Release'
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
        },

        _getDefaultFields: function() {
            return ['Discussion', 'PreliminaryEstimate', 'UserStories', 'Milestones'];
        }
    });
})();

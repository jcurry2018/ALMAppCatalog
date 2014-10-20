(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.iterationplanningboard.IterationPlanningBoardApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.ui.gridboard.planning.TimeboxGridBoard',
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.gridboard.plugin.GridBoardManageIterations',
            'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl'
        ],
        mixins: ['Rally.app.CardFieldSelectable'],
        modelNames: ['User Story', 'Defect'],

        config: {
            defaultSettings: {
                cardFields: 'Parent,Tasks,Defects,Discussion,PlanEstimate'
            }
        },

        launch: function() {
            var plugins = [
                {
                    ptype: 'rallygridboardaddnew',
                    rankScope: 'BACKLOG'
                },
                {
                    ptype: 'rallygridboardcustomfiltercontrol',
                    filterControlConfig: {
                        margin: '3 9 3 30',
                        blackListFields: ['Iteration', 'PortfolioItem'],
                        modelNames: this.modelNames,
                        stateful: true,
                        stateId: this.getContext().getScopedStateId('iteration-planning-custom-filter-button')
                    },
                    showOwnerFilter: true,
                    ownerFilterControlConfig: {
                        stateful: true,
                        stateId: this.getContext().getScopedStateId('iteration-planning-owner-filter')
                    }
                }
            ];

            if (this.getContext().getSubscription().isHsEdition() || this.getContext().getSubscription().isExpressEdition()) {
                plugins.push('rallygridboardmanageiterations');
            }

            this.gridboard = this.add({
                xtype: 'rallytimeboxgridboard',
                context: this.getContext(),
                modelNames: this.modelNames,
                timeboxType: 'Iteration',
                shouldDestroyTreeStore: this.getContext().isFeatureEnabled('S73617_GRIDBOARD_SHOULD_DESTROY_TREESTORE'),
                plugins: plugins,
                cardBoardConfig: {
                    cardConfig: {
                        fields:  this.getCardFieldNames()
                    },
                    columnConfig: {
                        additionalFetchFields: ['PortfolioItem']
                    },
                    listeners: {
                        filter: this._onBoardFilter,
                        filtercomplete: this._onBoardFilterComplete,
                        scope: this
                    }
                },
                listeners: {
                    load: this._onLoad,
                    toggle: this._publishContentUpdated,
                    recordupdate: this._publishContentUpdatedNoDashboardLayout,
                    recordcreate: this._publishContentUpdatedNoDashboardLayout,
                    preferencesaved: this._publishPreferenceSaved,
                    scope: this
                }
            });
        },

        getSettingsFields: function () {
            var fields = this.callParent(arguments);
            this.appendCardFieldPickerSetting(fields);
            return fields;
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

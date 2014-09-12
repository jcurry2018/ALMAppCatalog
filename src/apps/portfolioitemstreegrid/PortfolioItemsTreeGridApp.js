(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', {
        extend: 'Rally.apps.common.PortfolioItemsGridBoardApp',
        requires: [
          'Rally.ui.grid.TreeGrid',
          'Rally.data.wsapi.TreeStoreBuilder',
          'Rally.ui.grid.plugin.TreeGridExpandedRowPersistence',
          //'Rally.ui.gridboard.plugin.GridBoardPortfolioItemTypeCombobox',
          'Rally.data.util.PortfolioItemTypeDefList'
        ],

        componentCls: 'pitreegrid',
        toggleState: 'grid',
        stateName: 'tree',

        mixins: [
            "Rally.clientmetrics.ClientMetricsRecordable"
        ],

        config: {
            defaultSettings: {
                columnNames: ['Name', 'PercentDoneByStoryPlanEstimate', 'PercentDoneByStoryCount', 'PreliminaryEstimate', 'PlannedStartDate', 'PlannedEndDate', 'ValueScore', 'RiskScore', 'InvestmentCategory']
            }
        },

        loadGridBoard: function () {
            if(!this.rendered) {
                this.on('afterrender', function(){
                    this._getPortfolioItemTypeDefArray();
                }, this, {single: true});
            } else {
                this._getPortfolioItemTypeDefArray();
            }
        },

        _getPortfolioItemTypeDefArray: function() {
            return Ext.create('Rally.data.util.PortfolioItemTypeDefList')
                .getArray(this.getContext().getDataContext())
                .then({
                    success: this._loadAppWithPortfolioItemType,
                    scope: this
                });
        },

        _loadAppWithPortfolioItemType: function(piTypeDefArray) {
            var allPiTypePaths = _.pluck(piTypeDefArray, 'TypePath');
            this._loadApp(allPiTypePaths);
        },

        _loadApp: function(allPiTypePaths) {
            this._getGridStore(allPiTypePaths).then({
                success: function(gridStore) {
                    this.addGridBoard({
                        gridStore: gridStore
                    });
                },
                scope: this
            });
        },

        _getGridStore: function(allPiTypePaths) {
            var storeConfig = Ext.apply(this.storeConfig || {}, {
                models: allPiTypePaths,
                autoLoad: false,
                remoteSort: true,
                root: {expanded: true},
                pageSize: 200,
                enableHierarchy: true,
                childPageSizeEnabled: true,
                fetch: this.columnNames
            });

            return Ext.create('Rally.data.wsapi.TreeStoreBuilder').build(storeConfig);
        },

        getFilterControlConfig: function () {
            return {
                margin: '3 10'
            };
        },

        getFieldPickerConfig: function () {
            return {
                gridFieldBlackList: [
                    'ObjectID',
                    'Description',
                    'DisplayColor',
                    'Notes',
                    'Subscription',
                    'Workspace',
                    'Changesets',
                    'RevisionHistory',
                    'Children',
                    'Successors',
                    'Predecessors'
                ],
                margin: '3 9 14 0'
            };
        },

        getGridConfig: function (options) {
            var context = this.getContext();
            var gridConfig = {
                xtype: 'rallytreegrid',
                store: options.gridStore,
                columnCfgs: this.getSetting('columnNames') || this.columnNames,
                summaryColumns: [],
                enableBulkEdit: true,
                plugins: [],
                stateId: context.getScopedStateId('portfolioitems-treegrid'),
                stateful: true,
                alwaysShowDefaultColumns: false,
                listeners: {
                    afterrender: this._onGridLoad,
                    scope: this
                }
            };

            if (context.isFeatureEnabled('EXPAND_ALL_TREE_GRID_CHILDREN')) {
                gridConfig.plugins.push({
                    ptype: 'rallytreegridexpandedrowpersistence',
                    enableExpandLoadingMask: !context.isFeatureEnabled('EXPAND_ALL_LOADING_MASK_DISABLE')
                });
            }

            return gridConfig;
        },

        _onGridLoad: function () {
            //Rally.environment.getMessageBus().publish(Rally.Message.piKanbanBoardReady);
            this.recordComponentReady();

            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this);
            }
        }
    });
})();

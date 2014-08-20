(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.treegrid.TreeGridApp', {
        extend: 'Rally.app.App',
        requires: [
          'Rally.ui.grid.TreeGrid',
          'Rally.ui.grid.plugin.TreeGridExpandedRowPersistence',
          'Rally.ui.gridboard.GridBoard',
          'Rally.ui.picker.MultiObjectPicker',
          'Rally.ui.gridboard.plugin.GridBoardFieldPicker'
        ],
        alias: 'widget.treegridapp',
        componentCls: 'treegrid',

        statePrefix: 'custom',

        config: {
            defaultSettings: {
                modelNames: ['PortfolioItem/Strategy'],
                columnNames: ['Name', 'Owner', 'Project', 'PercentDoneByStoryPlanEstimate', 'PercentDoneByStoryCount', 'PlannedStartDate', 'PlannedEndDate']
            }
        },

        launch: function () {
            if(!this.rendered) {
                this.on('afterrender', this._loadApp, this, {single: true});
            } else {
                this._loadApp();
            }
        },

        _loadApp: function() {
            this._getGridStore().then({
                success: function(gridStore) {
                    this._addGridBoard(gridStore);
                },
                scope: this
            });
        },

        _addGridBoard: function(gridStore) {
            var context = this.getContext(),
                gridStateString = this.statePrefix + '-treegrid',
                gridStateId = context.getScopedStateId(gridStateString),
                gridboardPlugins = this._getGridBoardPlugins();

            this.gridboard = this.add({
                itemId: 'gridBoard',
                xtype: 'rallygridboard',
                stateId: this.statePrefix + '-gridboard',
                context: context,
                plugins: gridboardPlugins,
                toggleState: 'grid',
                modelNames: this.modelNames,
                cardBoardConfig: {},
                gridConfig: this._getGridConfig(gridStore, context, gridStateId),
                storeConfig: {},
                height: this._getHeight()
            });
        },

        _getGridBoardPlugins: function() {
            var plugins = [],
                context = this.getContext();

            var alwaysSelectedValues = ['FormattedID', 'Name', 'Owner'];
            if (context.getWorkspace().WorkspaceConfiguration.DragDropRankingEnabled) {
                alwaysSelectedValues.push('DragAndDropRank');
            }

            plugins.push({
                ptype: 'rallygridboardfieldpicker',
                headerPosition: 'left',
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
                margin: '3 9 14 0',
                alwaysSelectedValues: alwaysSelectedValues,
                modelNames: this.modelNames
            });

            return plugins;
        },

        _getHeight: function() {
            return this.getHeight() || 300;
        },

        _getGridConfig: function(gridStore, context, stateId) {
            var gridConfig = {
                xtype: 'rallytreegrid',
                store: gridStore,
                columnCfgs: this.getSetting('columnNames') || this.columnNames,
                summaryColumns: [],
                enableBulkEdit: false,
                plugins: [],
                stateId: stateId,
                stateful: true,
                alwaysShowDefaultColumns: false,
                listeners: {
                    'staterestore': {
                        fn: this._onGridStateRestore,
                        single: true,
                        store: gridStore
                    },
                    'render': {
                        fn: this._onGridRender,
                        single: true,
                        stateId: stateId,
                        store: gridStore
                    },
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

        _getGridStore: function() {
            var modelNames = this.getSetting('modelNames') || this.modelNames;
            modelNames = _.isString(modelNames) ? modelNames.split(',') : modelNames;

            var storeConfig = Ext.apply(this.storeConfig || {}, {
                    models: modelNames,
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

        _onGridStateRestore: function(grid) {
            grid.getStore().load();
        },

        _onGridRender: function(grid, options) {
            this._handleInitialStatelessLoad(options.store, options.stateId);
        },

        _handleInitialStatelessLoad: function(store, stateId) {
            var state = Ext.state.Manager.get(stateId);
            if (!state) {
                store.load();
            }
        }
    });

})();

(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.treegrid.TreeGridApp', {
        extend: 'Rally.app.App',
        requires: [
          'Rally.ui.grid.TreeGrid',
          'Rally.ui.grid.plugin.TreeGridExpandedRowPersistence',
          'Rally.ui.gridboard.GridBoard',
          'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
          'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl',
          'Rally.data.PreferenceManager',
          'Rally.data.wsapi.TreeStoreBuilder'
        ],
        alias: 'widget.treegridapp',
        componentCls: 'treegrid',

        statePrefix: 'custom',
        loadGridAfterStateRestore: true,

        autoScroll: false,

        config: {
            defaultSettings: {
                modelNames: ['PortfolioItem/Strategy'],
                columnNames: ['Name', 'Owner', 'Project', 'PercentDoneByStoryPlanEstimate', 'PercentDoneByStoryCount', 'PlannedStartDate', 'PlannedEndDate']
            }
        },

        getModelNamesArray: function(modelNames) {
            modelNames = modelNames || this.getSetting('modelNames') || this.modelNames;
            return _.isString(modelNames) ? modelNames.split(',') : modelNames;
        },

        launch: function () {
            if(!this.rendered) {
                this.on('afterrender', function(){
                    this._loadApp();
                }, this, {single: true});
            } else {
                this._loadApp();
            }
        },

        _loadApp: function(modelNames) {
            var modelNamesArray = this.getModelNamesArray(modelNames);

            this._getGridStore(modelNamesArray).then({
                success: function(gridStore) {
                    this._addGridBoard(gridStore, modelNamesArray);
                },
                scope: this
            });
        },

        _addGridBoard: function(gridStore, modelNamesArray) {
            this.gridboard = this.add(this._getGridBoardConfig(gridStore, modelNamesArray));
        },

        _getGridBoardConfig: function (gridStore, modelNamesArray) {
            var context = this.getContext(),
                gridStateString = this.statePrefix + '-treegrid',
                gridStateId = context.getScopedStateId(gridStateString),
                gridboardPlugins = this._getGridBoardPlugins(modelNamesArray);

            return {
                itemId: 'gridBoard',
                xtype: 'rallygridboard',
                stateId: this.statePrefix + '-gridboard',
                context: context,
                shouldDestroyTreeStore: this.getContext().isFeatureEnabled('S73617_GRIDBOARD_SHOULD_DESTROY_TREESTORE'),
                plugins: gridboardPlugins,
                toggleState: 'grid',
                modelNames: modelNamesArray,
                cardBoardConfig: {},
                gridConfig: this._getGridConfig(gridStore, context, gridStateId),
                storeConfig: {},
                height: this._getHeight()
            };
        },

        _getGridBoardPlugins: function(modelNamesArray) {
            var plugins = [],
                context = this.getContext();

            var alwaysSelectedValues = ['FormattedID', 'Name'];
            if (context.getWorkspace().WorkspaceConfiguration.DragDropRankingEnabled) {
                alwaysSelectedValues.push('DragAndDropRank');
            }

            if (this.filterControlConfig) {
                plugins.push({
                    ptype: 'rallygridboardcustomfiltercontrol',
                    filterChildren: false,
                    filterControlConfig: Ext.merge({
                        context: this.getContext(),
                        margin: '3 10',
                        modelNames: modelNamesArray
                    }, this.filterControlConfig)
                });
            }

            plugins.push({
                ptype: 'rallygridboardfieldpicker',
                headerPosition: 'left',
                gridFieldBlackList: [
                    'ObjectID',
                    'Description',
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
                gridAlwaysSelectedValues: alwaysSelectedValues,
                modelNames: modelNamesArray
            });

            return plugins;
        },

        _getHeight: function() {
            return this.getHeight() || 300;
        },

        _getGridConfig: function(gridStore, context, stateId) {
            var gridListeners = {};
            if (this.loadGridAfterStateRestore) {
                gridListeners = {
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
                };
            }

            var gridConfig = {
                xtype: 'rallytreegrid',
                store: gridStore,
                columnCfgs: this.getSetting('columnNames') || this.columnNames,
                summaryColumns: [],
                enableBulkEdit: true,
                plugins: [],
                stateId: stateId,
                stateful: true,
                alwaysShowDefaultColumns: false,
                listeners: gridListeners,
                bufferedRenderer: this.getContext().isFeatureEnabled('S69537_BUFFERED_RENDERER_TREE_GRID')
            };

            gridConfig.plugins.push({
                ptype: 'rallytreegridexpandedrowpersistence'
            });

            return gridConfig;
        },

        _getGridStore: function(modelNames) {
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

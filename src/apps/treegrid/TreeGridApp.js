(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.treegrid.TreeGridApp', {
        extend: 'Rally.app.App',
        requires: [
          'Rally.ui.grid.TreeGrid',
          'Rally.ui.grid.plugin.TreeGridExpandedRowPersistence',
          'Rally.ui.gridboard.GridBoard'
        ],
        alias: 'widget.treegridapp',
        componentCls: 'treegrid',

        statePrefix: 'custom',

        config: {
            defaultSettings: {
                modelNames: ['PortfolioItem/Initiative'],
                columnNames: ['Name', 'Owner', 'Project', 'PlannedStartDate', 'PlannedEndDate']
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
                stateString = this.statePrefix + '-treegrid',
                stateId = context.getScopedStateId(stateString),
                gridboardPlugins = [];

            this.add({
                itemId: 'gridBoard',
                xtype: 'rallygridboard',
                stateId: this.statePrefix + '-gridboard',
                context: context,
                plugins: gridboardPlugins,
                toggleState: 'grid',
                modelNames: this.modelNames,
                cardBoardConfig: {},
                gridConfig: this._getGridConfig(gridStore, context, stateId),
                storeConfig: {},
                height: this._getHeight()
            });
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
                alwaysShowDefaultColumns: true,
                listeners: {
                    staterestore: this._onGridStateRestore,
                    single: true,
                    scope: gridStore
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
                    pageSize: 25,
                    enableHierarchy: true,
                    childPageSizeEnabled: true,
                    fetch: this.columnNames
                });

            return Ext.create('Rally.data.wsapi.TreeStoreBuilder').build(storeConfig);
        },

        _onGridStateRestore: function() {
            //scope of this function is the grid's store
            this.load();
        }
    });

})();

(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.treegrid.TreeGridApp', {
        extend: 'Rally.app.App',
        requires: [
          'Rally.ui.grid.TreeGrid',
          'Rally.ui.grid.plugin.TreeGridExpandedRowPersistence',
          'Rally.ui.gridboard.GridBoard',
          'Rally.ui.picker.PillPicker',
          'Rally.ui.picker.MultiObjectPicker'
        ],
        alias: 'widget.treegridapp',
        componentCls: 'treegrid',

        config: {
            defaultSettings: {
                modelNames: ['PortfolioItem/Initiative'],
                columnNames: ['Name', 'Owner', 'Project']
            }
        },

        launch: function () {
            this._getGridStore().then({
                success: function(gridStore) {
                    this._addGridBoard(gridStore);
                },
                scope: this
            });
        },

        getSettingsFields: function() {
            var artifactQuery = '((((((TypePath = "hierarchicalrequirement") OR (TypePath = "defect")) OR (TypePath = "defectsuite")) OR (TypePath = "testset")) OR (TypePath = "testcase")) OR (Parent.TypePath = "portfolioitem"))';

            return [{
                xtype: 'rallypillpicker',
                showPills: true,
                name: 'modelNames',
                comboBoxCfg: {
                    xtype: 'rallymultiobjectpicker',
                    name: 'modelNames',
                    fieldLabel: 'Objects',
                    labelWidth: 75,
                    labelSeparator: '',
                    width: 400,
                    remoteFilter: false,
                    modelType: 'TypeDefinition',
                    selectionKey: 'TypePath',
                    storeLoadOptions: {
                        params: {
                            order: 'Name ASC',
                            fetch: 'Name,TypePath',
                            query: artifactQuery
                        }
                    }
                }
            }];
        },

        _addGridBoard: function(gridStore) {
            var context = this.getContext(),
                stateString = 'custom-treegrid',
                stateId = context.getScopedStateId(stateString);

            this.add({
                itemId: 'gridBoard',
                xtype: 'rallygridboard',
                stateId: 'iterationtracking-gridboard',
                context: context,
                plugins: [],
                toggleState: 'grid',
                modelNames: this.modelNames,
                cardBoardConfig: {},
                gridConfig: this._getGridConfig(gridStore, context, stateId),
                storeConfig: {},
                height: this.getHeight()
            });
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
                stateful: true
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

            var context = this.getContext(),
                storeConfig = Ext.apply(this.storeConfig || {}, {
                    models: modelNames,
                    autoLoad: true,
                    remoteSort: true,
                    root: {expanded: true},
                    pageSize: 200,
                    enableHierarchy: true,
                    childPageSizeEnabled: true,
                    useShallowFetch: context.isFeatureEnabled('COMPACT_WSAPI_REQUESTS') ? false : true,
                    fetch: this.columnNames
                });

            return Ext.create('Rally.data.wsapi.TreeStoreBuilder').build(storeConfig);
        }
    });

})();

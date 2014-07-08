(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.treegrid.TreeGridApp', {
        extend: 'Rally.app.App',
        requires: [
          'Rally.ui.grid.TreeGrid',
          'Rally.ui.grid.plugin.TreeGridExpandedRowPersistence'
        ],
        alias: 'widget.treegridapp',
        componentCls: 'treegrid',

        modelNames: ['User Story', 'Defect', 'Defect Suite', 'Test Set'],

        launch: function () {
            var plugins = [],
                context = this.getContext();

            if (context.isFeatureEnabled('EXPAND_ALL_TREE_GRID_CHILDREN')) {
                plugins.push({
                    ptype: 'rallytreegridexpandedrowpersistence',
                    enableExpandLoadingMask: !context.isFeatureEnabled('EXPAND_ALL_LOADING_MASK_DISABLE')
                });
            }

            this._getGridStore().then({
                success: function(gridStore) {
                    this.add({
                        xtype: 'rallytreegrid',
                        plugins: plugins,
                        store: gridStore,
                        columnCfgs: ['Name', 'Owner', 'Project', 'Discussion'],
                        stateId: this.getContext().getScopedStateId('custom-treegrid'),
                        stateful: true
                    });

                    gridStore.load();
                },
                scope: this
            });
        },

        _getGridStore: function() {
            var context = this.getContext(),
                config = {
                    models: this.modelNames,
                    autoLoad: false,
                    remoteSort: true,
                    root: {expanded: true},
                    enableHierarchy: true,
                    childPageSizeEnabled: true,
                    useShallowFetch: context.isFeatureEnabled('COMPACT_WSAPI_REQUESTS') ? false : true
                };

            return Ext.create('Rally.data.wsapi.TreeStoreBuilder').build(config);
        }
    });

})();

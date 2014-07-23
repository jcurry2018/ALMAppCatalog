(function() {
    var Ext = window.Ext4 || window.Ext;

    /**
     *
     */
    Ext.define('Rally.apps.iterationtrackingboard.IterationTrackingTreeGrid', {
        extend: 'Rally.ui.grid.TreeGrid',
        alias: 'widget.rallyiterationtrackingtreegrid',

        requires: [
            'Rally.apps.iterationtrackingboard.IterationTrackingTreeView',
            'Rally.ui.renderer.RendererFactory'
        ],

        config: {
            viewConfig: {
                xtype: 'rallyiterationtrackingtreeview'
            },

            /**
             * @cfg {String}
             * @inheritdoc
             */
            treeColumnDataIndex: 'FormattedID',

            /**
             * @cfg {String}
             * @inheritdoc
             */
            treeColumnHeader: 'ID',

            /**
             * @cfg {boolean}
             * @inheritdoc
             */
            treeColumnResizable: false,

            /**
             * @cfg {Array}
             * Array of configurations for summary e.g. {field: 'PlanEstimate', type: 'sum', units: 'pt'}
             */
            summaryColumns: [
                {
                    field: 'PlanEstimate',
                    type: 'sum',
                    units: 'pt'
                },
                {
                    field: 'TaskEstimateTotal',
                    type: 'sum',
                    units: 'hr'
                },
                {
                    field: 'TaskRemainingTotal',
                    type: 'sum',
                    units: 'hr'
                }
            ],

            treeColumnRenderer: function (value, metaData, record, rowIdx, colIdx, store) {
                store = store.treeStore || store;
                return Rally.ui.renderer.RendererFactory.getRenderTemplate(store.model.getField('FormattedID')).apply(record.data);
            }
        }
    });
})();

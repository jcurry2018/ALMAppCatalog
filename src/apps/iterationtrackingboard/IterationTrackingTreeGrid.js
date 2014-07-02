(function() {
    var Ext = window.Ext4 || window.Ext;

    /**
     *
     */
    Ext.define('Rally.apps.iterationtrackingboard.IterationTrackingTreeGrid', {
        extend: 'Rally.ui.grid.TreeGrid',
        alias: 'widget.rallyiterationtrackingtreegrid',

        requires: [
            'Rally.apps.iterationtrackingboard.IterationTrackingTreeView'
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

            treeColumnRenderer: undefined,

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
            ]
        }
    });
})();

(function() {
    var Ext = window.Ext4 || window.Ext;

    /**
     *
     */
    Ext.define('Rally.apps.iterationtrackingboard.IterationTrackingTreeGrid', {
        extend: 'Rally.ui.grid.TreeGrid',
        alias: 'widget.rallyiterationtrackingtreegrid',

        requires: ['Rally.ui.renderer.RendererFactory'],

        config: {
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

            noDataHelpLink: {
                url: "https://help.rallydev.com/tracking-iterations#filter",
                title: "Filter Help Page"
            }
        }
    });
})();

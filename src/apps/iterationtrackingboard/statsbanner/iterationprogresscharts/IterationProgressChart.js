(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define("Rally.apps.iterationtrackingboard.statsbanner.iterationprogresscharts.IterationProgressChart", {
            requires: [
                "Rally.ui.chart.Chart"
            ],

            chartComponentConfig: {
               xtype: "rallychart",
               suppressClientMetrics: true /* keeps rallychart::lookback query time from displaying in client metrics */
            }
        });
}());

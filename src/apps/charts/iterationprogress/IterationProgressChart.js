(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define("Rally.apps.charts.iterationprogress.IterationProgressChart", {
            requires: [
                "Rally.ui.chart.Chart"
            ],

            chartComponentConfig: {
               xtype: "rallychart",
               itemId: "iterationprogresschart",
               suppressClientMetrics: true /* keeps rallychart::lookback query time from displaying in client metrics */
            }
        });
}());

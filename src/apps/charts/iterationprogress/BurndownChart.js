(function(){
    var Ext = window.Ext4 || window.Ext;

    Ext.define("Rally.apps.charts.iterationprogress.BurndownChart", {
        alias: "widget.rallyburndownchart",
        extend: "Ext.Container",
        requires: [ 'Rally.ui.chart.Chart' ],
        mixins: [
            "Rally.apps.charts.iterationprogress.IterationProgressMixin",
            "Rally.apps.charts.iterationprogress.IterationProgressChart"
        ],

        currentScope: undefined,
        context: undefined,
        height: undefined,
        width: undefined,
        onChartDataLoaded: Ext.emptyFn,

        constructor: function(config) {
            this.mergeConfig(config);
            this.callParent(arguments);
        },

        initComponent: function() {
            this.callParent(arguments);

            Ext.Ajax.request({
                url: "/slm/charts/itsc.sp?sid=&iterationOid=" + this.currentScope.getRecord().get('ObjectID') + "&cpoid=" + this.context.getProject().ObjectID,
                method: 'GET',
                withCredentials: true,
                success: function (response, request) {
                    this._loadData(response.responseText);
                },
                requester: this,
                scope: this
            });
        },

        _loadData: function(chartData) {
            var xmlDoc = this._createChartDatafromXML(chartData);
            this._createBurndownChartDatafromXML(xmlDoc);
        },

        _createBurndownConfig: function() {
            return Ext.Object.merge({
               chartColors: ["#005eb8", "#666666", "#8dc63f" ],

               chartConfig: {
                    chart: {
                        zoomType: 'xy',
                        alignTicks: false,
                        animation: false
                    },
                    plotOptions: {
                        series: {
                            animation: false,
                            shadow: false, // at the request of the UI team
                            borderWidth: 0
                        }
                    },
                    legend: { enabled: true },
                    title: { text: null },
                    xAxis: {
                        tickmarkPlacement: 'on',
                        tickInterval: 1
                    },
                    yAxis: [
                        {
                            title: { text: null },
                            min: 0,
                            labels: { style: { color: "#005eb8" } }
                        },
                        {
                           title: { text: null },
                           min: 0,
                           labels: { style: { color: "#8dc63f" } },
                           opposite: true
                        }
                    ]
               },
               chartData: {
                   categories: [ ],
                   series: [
                       {
                           name: "To Do",
                           type: "column",
                           data: [  ],
                           tooltip: { valueDecimals: 1, valueSuffix: ' Hours' }
                       },
                       {
                           name: "Ideal",
                           type: "line",
                           dashStyle: "Solid",
                           data: [ ],
                           marker : {
                               enabled : true,
                               radius : 3
                           },
                           tooltip: { valueDecimals: 1, valueSuffix: ' Hours' }
                       },
                       {
                           name: "Accepted",
                           type: "column",
                           data: [ ],
                           yAxis: 1,
                           tooltip: { valueDecimals: 1, valueSuffix: ' Points' }
                       }
                   ]
               }
           }, Rally.apps.charts.iterationprogress.IterationProgressChart.prototype.chartComponentConfig);
        },

        _createBurndownChartDatafromXML: function (xmlDoc) {

            this.chartComponentConfig = this._createBurndownConfig();

            var xmlChartData = xmlDoc.getElementsByTagName("chart_data")[0];
            var xmlChartValueText = xmlDoc.getElementsByTagName("chart_value_text")[0];
            var draw = xmlDoc.getElementsByTagName("draw")[0];
            var axis_value = xmlDoc.getElementsByTagName("axis_value")[1];

            var rows = xmlChartData.getElementsByTagName("row");

            // this makes no sense...The thing labeled Accepted in the <chart_data> element, isn't.
            // The thing that is Accepted, is buried in the <chart_value_text> element

            this.chartComponentConfig.chartData.categories = this._getStringValues(rows[0].getElementsByTagName("string")); // categories
            this.chartComponentConfig.chartData.series[0].data = this._getNumberValues(rows[1].getElementsByTagName("number")); //todo;
            this.chartComponentConfig.chartData.series[1].data = this._getNumberValues(rows[3].getElementsByTagName("number")); //ideal;
            this.chartComponentConfig.chartData.series[2].data = this._getNumberValues(xmlChartValueText.getElementsByTagName("row")[2].getElementsByTagName("number")); //accepted;
            this.chartComponentConfig.chartConfig.yAxis[0].max = axis_value.getAttribute("max") * 1;

            var texts = draw.getElementsByTagName("text");
            // find the last <text element with orientation="vertical_down" attribute, that's the max y-axis 2 setting
            for (i = 0; i < texts.length; i++) {
                if (texts[i].getAttribute("orientation") === "vertical_down") {
                    this.chartComponentConfig.chartConfig.yAxis[1].max = (this._getElementValue(texts[i]) * 1);
                }
            }
            this._configureYAxisIntervals();

            this.chartComponentConfig.chartConfig.xAxis.tickInterval = Math.floor(this.chartComponentConfig.chartData.series[0].data.length / 4);

            this.onChartDataLoaded(this.chartComponentConfig);
        }
    });
})();
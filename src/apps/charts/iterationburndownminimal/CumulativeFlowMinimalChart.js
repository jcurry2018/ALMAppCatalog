(function(){
    var Ext = window.Ext4 || window.Ext;

    Ext.define("Rally.apps.charts.iterationburndownminimal.CumulativeFlowMinimalChart", {
        alias: "widget.rallycumulativeflowchart",
        extend: "Ext.Container",
        requires: [ 'Rally.ui.chart.Chart' ],
        mixins: [
            "Rally.apps.charts.iterationburndownminimal.IterationBurnDownMinimalMixin",
            "Rally.apps.charts.iterationburndownminimal.IterationBurnDownMinimalChart"
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
                url: "/slm/charts/icfc.sp?sid=&iterationOid=" + this.currentScope.getRecord().get('ObjectID') + "&bigChart=true&cpoid=" + this.context.getProject().ObjectID,
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
            this._createCumulativeFlowChartDatafromXML(xmlDoc);
        },

        _createCFDConfig: function() {
            return Ext.Object.merge({
               chartColors: [  // RGB values obtained from here: http://ux-blog.rallydev.com/?cat=23
                                "#C0C0C0",  // $grey4
                                "#FF8200",  // $orange
                                "#F6A900",  // $gold
                                "#FAD200",  // $yellow
                                "#8DC63F",  // $lime
                                "#1E7C00",  // $green_dk
                                "#337EC6",  // $blue_link
                                "#005EB8",  // $blue
                                "#7832A5",  // $purple
                                "#DA1884"   // $pink
                            ],
               chartConfig: {
                    chart: {
                        zoomType: 'xy',
                        alignTicks: false,
                        animation: false,
                        type: "area"
                    },
                    plotOptions: {
                                    series: {
                                        animation: false,
                                        marker: {
                                            enabled: false
                                        }
                                    },
                                    area: {
                                        stacking: 'normal'
                                    }
                                 },
                    legend: {
                            enabled: true
                    },
                    title: { text: null },
                    xAxis: {
                        tickmarkPlacement: 'on',
                        tickInterval: 1
                    },
                    yAxis: [
                        {
                            title: {
                                text: "Plan Estimate"
                            },
                            min: 0,
                            labels: {
                                style: { color: "#005eb8" }
                            }
                        } ]

               },
               chartData: {
                   categories: [ ],
                   series: [ ]
               }
           }, Rally.apps.charts.iterationburndownminimal.IterationBurnDownMinimalChart.prototype.chartComponentConfig);
        },

        _createCumulativeFlowChartDatafromXML: function (xmlDoc) {

            this.chartComponentConfig = this._createCFDConfig();

            var xmlChartData = xmlDoc.getElementsByTagName("chart_data")[0];

            var rows = xmlChartData.getElementsByTagName("row");
            var i, j;
            this.chartComponentConfig.chartData.categories = this._getStringValues(rows[0].getElementsByTagName("string")); // categories
            for(j=rows.length-1, i = 0 ; j > 0; j--,i++) {
                this.chartComponentConfig.chartData.series[i] = {};
                this.chartComponentConfig.chartData.series[i].data = this._getNumberValues(rows[j].getElementsByTagName("number"));
                this.chartComponentConfig.chartData.series[i].name = this._getStringValues(rows[j].getElementsByTagName("string"))[0];
            }

            // the 'max' y axis value in the xml isn't correct, so we'll calculate it ourselves...
            this.chartComponentConfig.chartConfig.yAxis[0].max = this._computeMaxYAxisValue(this.chartComponentConfig.chartData.series);

            this._configureYAxisIntervals();


            // Use number of ScheduleState values to show as a surrogate for with of the legend text.
            if(this.chartComponentConfig.chartData.series.length === 6) {
                this.chartComponentConfig.chartConfig.legend.itemStyle = { fontSize: '8px'};
            } else if(this.chartComponentConfig.chartData.series.length === 5) {
                this.chartComponentConfig.chartConfig.legend.itemStyle = { fontSize: '10px'};
            } // else it will default to 12px

            this.chartComponentConfig.chartConfig.xAxis.tickInterval = Math.floor(this.chartComponentConfig.chartData.series[0].data.length / 4);

            this.onChartDataLoaded(this.chartComponentConfig);
        }

    });

})();
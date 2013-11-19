(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.charts.iterationburndownminimal.IterationBurnDownMinimalApp', {
        extend: 'Rally.app.TimeboxScopedApp',

        settingsScope: 'workspace',

        mixins: [
            'Rally.apps.charts.iterationburndownminimal.IterationBurnDownMinimalChart'
        ],

        cls: 'iterationburndownminimal-app',

        items: [
            {
                xtype: 'container',
                itemId: 'header',
                cls: 'header'
            },
            {
                xtype: 'rallybutton',
                text: 'Cumulative Flow',
                cls: 'primary small',
                itemId: 'cfdSwapButton',
                style: {
                    'float': 'right'
                },
                scope: this,
		        handler : function(btn) {
                    if (btn.text == "Cumulative Flow") {
                        btn.setText("Burndown");
                    } else {
                        btn.setText("Cumulative Flow");
                    }

                    var app = btn.up('rallyapp');
                    app._cfdSwapButtonClicked();
                }
            }
        ],

        clientMetrics: [
                    {
                        beginMethod: '_getIterationData',
                        endMethod: '_createChartDatafromXML',
                        description: 'IterationBurnDownMinimalApp - call A0 endpoint to get data'
                        },
                    {
                        beginEvent: 'updateBeforeRender',
                        endEvent: 'updateAfterRender',
                        description: 'IterationBurnDownMinimalApp - chart rendering time'
                        }
        ],

        scopeType: "iteration",
        scopeObject: undefined,
        chartType: "burndown",

        _cfdSwapButtonClicked: function () {
//            this._onScopeObjectLoaded(this.getContext().getTimeboxScope().record);
            if (this.chartType == "cumulativeflow") {
                this.chartType = "burndown";
            } else {
                this.chartType = "cumulativeflow";
            }
            this._getIterationData(this.scopeObject);
        },

        onScopeChange: function (scope) {
            this._onScopeObjectLoaded(scope.getRecord());
        },

        launch: function () {
            this.callParent(arguments);
            this._setupEvents();
            this._setupUpdateBeforeRender();
            this.subscribe(this, Rally.Message.objectUpdate, this._onMessageFromObjectUpdate, this);
        },

        _setupUpdateBeforeRender: function () {
            this.chartComponentConfig.updateBeforeRender = this._setupDynamicHooksWithEvents(
                this.chartComponentConfig.updateBeforeRender,
                'updateBeforeRender'
            );

            this.chartComponentConfig.updateAfterRender = this._setupDynamicHooksWithEvents(
                this.chartComponentConfig.updateAfterRender,
                'updateAfterRender'
            );
        },

        _setupDynamicHooksWithEvents: function (func, event) {
            var self = this;

            return function () {
                self.fireEvent(event);
                if (_.isFunction(func)) {
                    func.apply(this);
                }
            };
        },

        _setupEvents: function () {
            this.addEvents(
                'updateBeforeRender',
                'updateAfterRender'
            );
        },

        _onMessageFromObjectUpdate: function(message) {
            this._onScopeObjectLoaded(this.getContext().getTimeboxScope().record);
        },

        _onScopeObjectLoaded: function (record) {
            this._setScopeFromData(record);
            this._getIterationData(record);
        },

        _setScopeFromData: function (record) {
            this.scopeObject = record;
        },

        _getElementValue: function (element) {
            if (element.textContent !== "undefined") {
                return element.textContent;
            }
            return element.text;
        },

        _configureYAxis: function(ticks, axis) {

            var intervalY = (this.chartComponentConfig.chartConfig.yAxis[axis].max - 0) / (ticks - 1);
            var ticksY = [];
            for (var i = 0; i < ticks; i++) {
                ticksY.push(i * intervalY);
            }
            this.chartComponentConfig.chartConfig.yAxis[axis].tickPositions = ticksY;
        },

        _configureYAxisIntervals: function () {
            var ticks = 5; // not much chart space, limit to 5
            this._configureYAxis(ticks, 0);
            if(this.chartType === "burndown") {
                this._configureYAxis(ticks, 1);
            }
        },

        _getStringValues: function (elements) {
            var i;
            var strings = [];
            for (i = 0; i < elements.length; i++) {
                strings.push(this._getElementValue(elements[i]));
            }
            return strings;
        },

        _getNumberValues: function (elements) {
            var i;
            var numbers = [];
            for (i = 0; i < elements.length; i++) {
                numbers.push(this._getElementValue(elements[i]).split(' ')[0] * 1);
            }
            return numbers;
        },

        _createChartDatafromXML: function (xml) {
            var parseXml;

            if (typeof window.DOMParser !== "undefined") {
                parseXml = function (xmlStr) {
                    return ( new window.DOMParser() ).parseFromString(xmlStr, "text/xml");
                };
            } else if (typeof window.ActiveXObject !== "undefined" &&
                new window.ActiveXObject("Microsoft.XMLDOM")) {
                parseXml = function (xmlStr) {
                    var xmlDoc = new window.ActiveXObject("Microsoft.XMLDOM");
                    xmlDoc.async = "false";
                    xmlDoc.loadXML(xmlStr);
                    return xmlDoc;
                };
            } else {
                throw new Error("No XML parser found");
            }
            var xmlDoc = parseXml(xml);

            if(this.chartType === "burndown") {
                this._createBurndownChartDatafromXML(xmlDoc);
            } else {
                this._createCumulativeFlowChartDatafromXML(xmlDoc);
            }
        },

        _createBurndownChartDatafromXML: function (xmlDoc) {
            this.chartComponentConfig.chartData.series = [
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
                                            ];
            this.chartComponentConfig.chartColors = ["#005eb8", "#666666", "#8dc63f" ];
            this.chartComponentConfig.chartConfig.chart.type = "undefined";
            this.chartComponentConfig.chartConfig.yAxis = [
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
                                 ];
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
            this.chartComponentConfig.chartConfig.plotOptions = { series: {animation: false}};

            this.chartComponentConfig.chartConfig.xAxis.tickInterval = this.chartComponentConfig.chartData.series[0].data.length / 5;

            this._addChart();
        },

        _createCumulativeFlowChartDatafromXML: function (xmlDoc) {

            this.chartComponentConfig.chartData.series = [];
            this.chartComponentConfig.chartConfig.chart.type = "area";

            this.chartComponentConfig.chartColors = [  // RGB values obtained from here: http://ux-blog.rallydev.com/?cat=23
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
                            ];
            var xmlChartData = xmlDoc.getElementsByTagName("chart_data")[0];
            //var axis_value = xmlDoc.getElementsByTagName("axis_value")[1];

            var rows = xmlChartData.getElementsByTagName("row");
            var i, j;
            this.chartComponentConfig.chartData.categories = this._getStringValues(rows[0].getElementsByTagName("string")); // categories
            for(j=rows.length-1, i = 0 ; j > 0; j--,i++) {
                this.chartComponentConfig.chartData.series[i] = {};
                this.chartComponentConfig.chartData.series[i].data = this._getNumberValues(rows[j].getElementsByTagName("number"));
                this.chartComponentConfig.chartData.series[i].name = this._getStringValues(rows[j].getElementsByTagName("string"))[0];
            }
            //this.chartComponentConfig.chartConfig.yAxis[0].max = axis_value.getAttribute("max") * 1;


            this._configureYAxisIntervals();
            this.chartComponentConfig.chartConfig.plotOptions = {
                                    series: {
                                        animation: false,
                                        marker: {
                                            enabled: false
                                        }
                                    },
                                    area: {
                                        stacking: 'normal'
                                    }
                                };
             this.chartComponentConfig.chartConfig.yAxis = [
                                                         {
                                                             title: { text: null },
                                                             min: 0,
                                                             labels: { style: { color: "#005eb8" } }
                                                         }
                                                     ];

            this.chartComponentConfig.chartConfig.xAxis.tickInterval = this.chartComponentConfig.chartData.series[0].data.length / 5;

            this._addChart();
        },

        _getIterationData: function (iteration) {
            this.setLoading();
            var url;
            if(this.chartType === "burndown") {
                url = "/slm/charts/itsc.sp?sid=&iterationOid=" + iteration.get('ObjectID') + "&cpoid=" + this.getContext().getProject().ObjectID;
            } else {
                url = "/slm/charts/icfc.sp?sid=&iterationOid=" + iteration.get('ObjectID') + "&bigChart=true&cpoid=" + this.getContext().getProject().ObjectID;
            }
            Ext.Ajax.request({
                url: url,
                method: 'GET',
                withCredentials: true,
                success: function (response, request) {
                    this._createChartDatafromXML(response.responseText);
                },
                scope: this
            });
        },

        _getHeight: function () {
            return (this.el) ? this.getHeight() : undefined;
        },
        _getWidth: function () {
            return (this.el) ? this.getWidth() : undefined;
        },

        _addChart: function () {
            this.remove('iterationburndownminimalchart', false);
            this.chartComponentConfig.chartConfig.chart.height = (this.height) ? this.height : this._getHeight();
            this.chartComponentConfig.chartConfig.chart.width = (this.width) ? this.width : this._getWidth();
            var chartComponentConfig = Ext.Object.merge({}, this.chartComponentConfig);
            this.add(chartComponentConfig);
            this.setLoading(false);
        }

    });
}());

(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.charts.iterationprogress.IterationProgressApp', {
        extend: 'Rally.app.TimeboxScopedApp',

        settingsScope: 'workspace',

        requires: [
            'Rally.apps.charts.iterationprogress.IterationProgressViewToggle',
            'Rally.apps.charts.iterationprogress.CumulativeFlowChart',
            'Rally.apps.charts.iterationprogress.BurndownChart',
            'Rally.apps.charts.iterationprogress.HeatmapChart'
        ],

        cls: 'iterationprogress-app',

        items: [],

        clientMetrics: [
            {
                beginMethod: '_getIterationData',
                endMethod: '_createChartDatafromXML',
                description: 'IterationProgressApp - call A0 endpoint to get data'
            },
            {
                beginEvent: 'updateBeforeRender',
                endEvent: 'updateAfterRender',
                description: 'IterationProgressApp - chart rendering time'
            },
            {
                componentReadyEvent: 'updateAfterRender'
            }
        ],

        scopeType: "iteration",
        scopeObject: undefined,
        chartType: "burndown",
        buttonPadding: 15,
        supportsUnscheduled: false,
        appName: 'Iteration Progress',

        onScopeChange: function (scope) {
            this.scope = scope;
            this._onScopeObjectLoaded(scope.getRecord());
            this.down('#toggle').show();
        },

        onNoAvailableTimeboxes: function() {
            this.remove('iterationprogresschart', false);
            this.down('#toggle').hide();
        },

        initComponent: function () {
            var heatmapEnabled = this.getContext().isFeatureEnabled('BETA_TRACKING_EXPERIENCE');
            this.chartType = heatmapEnabled ? "heatmap" : this.chartType;
            this.callParent(arguments);

            this.buttonContainer = this.add({
                xtype: 'container',
                itemId: 'buttonContainer',
                padding: ''+this.buttonPadding+' '+this.buttonPadding
            });

            this.buttonContainer.add({
                itemId: 'toggle',
                xtype: 'rallyiterationprogressviewtoggle',
                stateful: true,
                style: {
                    'display':'block',
                    'margin-left':'auto',
                    'margin-right':'auto'
                },
                listeners: {
                    toggle: this._onViewToggle,
                    scope: this
                },
                iterationBurndownMinimalConfig: {
                    heatmapEnabled : heatmapEnabled
                }
            });

            this._setupEvents();
            this.subscribe(this, Rally.Message.objectCreate, this._onMessageFromObjectUpdate, this);
            this.subscribe(this, Rally.Message.objectUpdate, this._onMessageFromObjectUpdate, this);
            this.subscribe(this, Rally.Message.objectDestroy, this._onMessageFromObjectUpdate, this);
            this.subscribe(this, Rally.Message.bulkUpdate, this._onMessageFromObjectUpdate, this);
        },

        _onViewToggle: function(toggleState) {
            this.chartType = toggleState;
            this._getIterationData(this.scopeObject);
        },

        _setupUpdateBeforeRender: function (chart) {
            chart.updateBeforeRender = this._setupDynamicHooksWithEvents(
                chart.updateBeforeRender,
                'updateBeforeRender'
            );

            chart.updateAfterRender = this._setupDynamicHooksWithEvents(
                chart.updateAfterRender,
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

        _getIterationData: function (iteration) {

            var typeMap = {
                heatmap: "Rally.apps.charts.iterationprogress.HeatmapChart",
                burndown: "Rally.apps.charts.iterationprogress.BurndownChart",
                cumulativeflow: "Rally.apps.charts.iterationprogress.CumulativeFlowChart"
            };
            
            if (iteration) {
                this.setLoading();
                Ext.create(typeMap[this.chartType], {
                    currentScope: this.scope,
                    context: this.getContext(),
                    onChartDataLoaded: Ext.bind(this._addChart, this)
                });
            }
        },

        _getHeight: function () {
            return (this.el) ? this.getHeight() : undefined;
        },
        _getWidth: function () {
            return (this.el) ? this.getWidth() : undefined;
        },

        _addChart: function (chart) {
            chart = chart || this.chartComponentConfig;
            this._setupUpdateBeforeRender(chart);
            this.setLoading();
            this.remove('iterationprogresschart', false);
            chart.chartConfig.chart.height = (this.height) ? this.height : this._getHeight();
            chart.chartConfig.chart.height -= (this.buttonContainer.getHeight() );
            chart.chartConfig.chart.width = (this.width) ? this.width : this._getWidth();

            chart.itemId = 'iterationprogresschart';
            this.add(chart);
            this.setLoading(false);
        }
    });
}());

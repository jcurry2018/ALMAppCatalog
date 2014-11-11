(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', {
        extend: 'Rally.apps.common.PortfolioItemsGridBoardApp',
        mixins: ['Rally.clientmetrics.ClientMetricsRecordable'],

        componentCls: 'pitreegrid',
        stateName: 'tree',

        config: {
            toggleState: 'grid',
            defaultSettings: {
                columnNames: [
                    'Name', 'Owner', 'PercentDoneByStoryPlanEstimate', 'PercentDoneByStoryCount',
                    'PreliminaryEstimate', 'PlannedStartDate', 'PlannedEndDate', 'ValueScore',
                    'RiskScore', 'InvestmentCategory'
                ]
            }
        },

        getGridConfig: function(options){
            var config = this.callParent(arguments);
            config.bufferedRenderer = this.getContext().isFeatureEnabled('S78545_ENABLE_BUFFERED_RENDERER_FOR_PI_PAGE');
            return config;
        }
    });
})();

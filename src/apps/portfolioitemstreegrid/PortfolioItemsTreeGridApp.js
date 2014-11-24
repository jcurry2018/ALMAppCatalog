(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', {
        extend: 'Rally.apps.common.PortfolioItemsGridBoardApp',
        mixins: ['Rally.clientmetrics.ClientMetricsRecordable'],
        requires: [
            'Rally.ui.gridboard.plugin.GridBoardActionsMenu',
            'Rally.ui.grid.TreeGridPrintDialog',
            'Rally.ui.dialog.CsvImportDialog'
        ],

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
            config.enableInlineAdd = this.getContext().isFeatureEnabled('F6038_ENABLE_INLINE_ADD');
            return config;
        },

        getGridBoardPlugins: function() {
            var plugins = this.callParent(arguments);

            if(this.getContext().isFeatureEnabled('PORTFOLIO_ITEMS_GRID_PAGE_ACTIONS')) {
                plugins.push({
                    ptype: 'rallygridboardactionsmenu',
                    itemId: 'printExportMenuButton',
                    menuItems: [
                        {
                            text: 'Import...',
                            handler: function() {
                                Ext.widget({
                                    xtype: 'rallycsvimportdialog',
                                    type: 'PortfolioItem',
                                    title: 'Import Portfolio Items'
                                });
                            }
                        },
                        {
                            text: 'Print...',
                            handler: function() {
                                Ext.create('Rally.ui.grid.TreeGridPrintDialog', {
                                    grid: this.gridboard.getGridOrBoard(),
                                    treeGridPrinterConfig: {
                                        largeHeaderText: 'Portfolio Items'
                                    }
                                });
                            },
                            scope: this
                        },
                        {
                            text: 'Export...',
                            handler: this._exportHandler,
                            scope: this
                        }
                    ],
                    buttonConfig: {
                        iconCls: 'icon-export',
                        toolTipConfig: {
                            html: 'Import/Export/Print',
                            anchor: 'top',
                            hideDelay: 0
                        },
                        style: {
                            'margin' : '3px 0 0 10px'
                        }
                    }
                });
            }
            return plugins;
        },

        _exportHandler: function(){
            var grid = this.gridboard.getGridOrBoard();
            var columns = _.map(grid.columnCfgs, function(config){
                return config.dataIndex || config;
            }).join();
            var order = grid.store.sorters.items[0].property + ' ' + grid.store.sorters.items[0].direction;
            var project = '/project/'+Rally.environment.getContext().getProject().OID;

            var finalFilter =  _.reduce(grid.store.filters.items, function(result, filter) {
                return result.and(filter);
            });

            window.location = window.location.origin+'/slm/webservice/v2.0/portfolioitem/'+this.piTypePicker.getSelectedType().get('Name')+'.csv?fetch='+columns+'&order='+order+'&project='+project+'&query='+(finalFilter ? finalFilter.toString() : '');
        }
    });
})();

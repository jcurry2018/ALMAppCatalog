(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', {
        extend: 'Rally.apps.treegrid.TreeGridApp',
        requires: [
          'Rally.ui.grid.TreeGrid',
          'Rally.ui.grid.plugin.TreeGridExpandedRowPersistence',
          'Rally.ui.gridboard.GridBoard',
          'Rally.ui.picker.PillPicker',
          'Rally.ui.picker.MultiObjectPicker'
        ],
        alias: 'widget.portfolioitemstreegridapp',
        componentCls: 'pitreegrid',

        statePrefix: 'portfolioitems',

        config: {
            defaultSettings: {
                modelNames: ['PortfolioItem/Initiative'],
                columnNames: ['Name', 'PreliminaryEstimate', 'ValueScore', 'RiskScore', 'InvestmentCategory']
            }
        }
    });
})();

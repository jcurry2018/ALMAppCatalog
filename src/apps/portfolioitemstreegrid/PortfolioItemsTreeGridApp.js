(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', {
        extend: 'Rally.apps.treegrid.TreeGridApp',
        requires: [
          'Rally.ui.grid.TreeGrid',
          'Rally.ui.grid.plugin.TreeGridExpandedRowPersistence',
          'Rally.ui.gridboard.GridBoard',
          'Rally.ui.gridboard.plugin.GridBoardPortfolioItemTypeCombobox',
          'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl',
          'Rally.data.util.PortfolioItemTypeDefList'
        ],
        alias: 'widget.portfolioitemstreegridapp',
        componentCls: 'pitreegrid',
        loadGridAfterStateRestore: false, //grid will be loaded once modeltypeschange event is fired from the type picker

        statePrefix: 'portfolioitems',

        config: {
            defaultSettings: {
                columnNames: ['Name', 'PercentDoneByStoryPlanEstimate', 'PercentDoneByStoryCount', 'PreliminaryEstimate', 'PlannedStartDate', 'PlannedEndDate', 'ValueScore', 'RiskScore', 'InvestmentCategory']
            }
        },

        launch: function() {
            if(!this.rendered) {
                this.on('afterrender', this._getPortfolioItemTypeDefArray, this, {single: true});
            } else {
                this._getPortfolioItemTypeDefArray();
            }
        },

        _getPortfolioItemTypeDefArray: function() {
            return Ext.create('Rally.data.util.PortfolioItemTypeDefList')
            .getArray(this.getContext().getDataContext())
            .then({
                success: this._loadAppWithPortfolioItemType,
                scope: this
            });
        },

        _loadAppWithPortfolioItemType: function(piTypeDefArray) {
            var allPiTypePaths = _.pluck(piTypeDefArray, 'TypePath');
            this._configureFilter(allPiTypePaths);

            this._loadApp(allPiTypePaths);
        },

        _configureFilter: function(allPiTypePaths) {
            var initialPiTypePath = allPiTypePaths[0];

            this.filterControlConfig = {
                blacklistFields: ['PortfolioItemType', 'State'],
                stateful: true,
                stateId: this.getContext().getScopedStateId('portfolio-tree-custom-filter-button'),
                whiteListFields: ['Milestones'],
                modelNames: [initialPiTypePath]
            };
        },

        _getGridBoardPlugins: function() {
            var plugins = this.callParent();
            plugins.push({
                ptype: 'rallygridboardpitypecombobox',
                context: this.getContext()
            });
            return plugins;
        }
    });
})();

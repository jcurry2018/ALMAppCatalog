(function() {
    var Ext = window.Ext4 || window.Ext;
    var appAutoScroll = Ext.isIE7 || Ext.isIE8;
    var gridAutoScroll = !appAutoScroll;

    Ext.define('Rally.apps.grid.GridApp', {
        extend: 'Rally.app.App',
        layout: 'fit',

        requires: [
            'Rally.data.util.Sorter',
            'Rally.data.wsapi.Filter',
            'Rally.ui.grid.Grid',
            'Rally.data.ModelFactory',
            'Rally.ui.grid.plugin.PercentDonePopoverPlugin'
        ],

        config: {
            defaultSettings: {
                types: 'hierarchicalrequirement'
            }
        },

        autoScroll: appAutoScroll,

        launch: function() {
            var context = this.getContext(),
                pageSize = this.getSetting('pageSize'),
                fetch = this.getSetting('fetch'),
                columns = this._getColumns(fetch);

            this.add({
                xtype: 'rallygrid',
                columnCfgs: columns,
                enableColumnHide: false,
                enableRanking: true,
                enableBulkEdit: context.isFeatureEnabled("EXT4_GRID_BULK_EDIT"),
                autoScroll: gridAutoScroll,
                plugins: this._getPlugins(columns),
                context: this.getContext(),
                storeConfig: {
                    fetch: fetch,
                    models: this.getSetting('types').split(','),
                    filters: this._getFilters(),
                    pageSize: pageSize,
                    sorters: Rally.data.util.Sorter.sorters(this.getSetting('order')),
                    listeners: {
                        load: this._updateAppContainerSize,
                        scope: this
                    }
                },
                pagingToolbarCfg: {
                    pageSizes: [pageSize]
                }
            });
        },

        onTimeboxScopeChange: function(newTimeboxScope) {
            this.callParent(arguments);

            this.down('rallygrid').getStore().reload({
                filters: this._getFilters()
            });
        },

        _getFilters: function() {
            var filters = [],
                query = this.getSetting('query'),
                timeboxScope = this.getContext().getTimeboxScope();
            if(query) {
                try {
                    query = new Ext.Template(query).apply({
                        user: Rally.util.Ref.getRelativeUri(this.getContext().getUser())
                    });
                } catch(e) {}
                filters.push(Rally.data.wsapi.Filter.fromQueryString(query));
            }

            if(timeboxScope && _.every(this.getSetting('types').split(','), this._isSchedulableType, this)) {
                filters.push(timeboxScope.getQueryFilter());
            }
            return filters;
        },

        _isSchedulableType: function(type) {
            return _.contains(['hierarchicalrequirement', 'task', 'defect', 'defectsuite', 'testset'], type.toLowerCase());
        },

        _getFetchOnlyFields:function(){
            return ['LatestDiscussionAgeInMinutes'];
        },

        _updateAppContainerSize: function() {
            if (this.appContainer) {
                var grid = this.down('rallygrid');
                grid.el.setHeight('auto');
                grid.body.setHeight('auto');
                grid.view.el.setHeight('auto');
                this.setSize({height: grid.getHeight() + _.reduce(grid.getDockedItems(), function(acc, item) {
                    return acc + item.getHeight() + item.el.getMargin('tb');
                }, 0)});
                this.appContainer.setPanelHeightToAppHeight();
            }
        },

        _getColumns: function(fetch){
            if (fetch) {
                return Ext.Array.difference(fetch.split(','), this._getFetchOnlyFields());
            }
            return [];
        },

        _getPlugins: function(columns) {
            var plugins = [];

            if (Ext.Array.intersect(columns, ['PercentDoneByStoryPlanEstimate','PercentDoneByStoryCount']).length > 0) {
                plugins.push('rallypercentdonepopoverplugin');
            }

            return plugins;
        }
    });
})();

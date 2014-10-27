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
            var pageSize = this.getSetting('pageSize'),
                fetch = this.getSetting('fetch'),
                columns = this._getColumns(fetch);

            this.add({
                xtype: 'rallygrid',
                columnCfgs: columns,
                enableColumnHide: false,
                enableRanking: true,
                enableBulkEdit: true,
                autoScroll: gridAutoScroll,
                plugins: this._getPlugins(columns),
                context: this.getContext(),
                storeConfig: {
                    fetch: fetch,
                    models: this.getSetting('types').split(','),
                    filters: this._getFilters(),
                    pageSize: pageSize,
                    sorters: Rally.data.util.Sorter.sorters(this.getSetting('order'))
                },
                pagingToolbarCfg: {
                    pageSizes: [pageSize]
                }
            });
        },

        onTimeboxScopeChange: function(newTimeboxScope) {
            this.callParent(arguments);

            this.down('rallygrid').filter(this._getFilters(), true, true);
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
                var filterObj = Rally.data.wsapi.Filter.fromQueryString(query);
                filterObj.itemId = filterObj.toString();
                filters.push(filterObj);
            }

            if(timeboxScope && _.every(this.getSetting('types').split(','), this._isSchedulableType, this)) {
                var timeboxFilterObj = timeboxScope.getQueryFilter();
                timeboxFilterObj.itemId = timeboxFilterObj.toString();
                filters.push(timeboxFilterObj);
            }
            return filters;
        },

        _isSchedulableType: function(type) {
            return _.contains(['hierarchicalrequirement', 'task', 'defect', 'defectsuite', 'testset'], type.toLowerCase());
        },

        _getFetchOnlyFields:function(){
            return ['LatestDiscussionAgeInMinutes'];
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

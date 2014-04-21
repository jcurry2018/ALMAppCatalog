(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.board.BoardApp', {
        extend: 'Rally.app.App',
        alias: 'widget.boardapp',
        requires: [
            'Rally.apps.board.Settings',
            'Rally.ui.cardboard.CardBoard'
        ],
        config: {
            defaultSettings: {
                type: 'HierarchicalRequirement',
                groupByField: 'ScheduleState',
                pageSize: 25,
                fields: 'FormattedID,Name,Owner',
                query: '',
                order: 'Rank'
            }
        },

        launch: function() {
            this.add({
                xtype: 'rallycardboard',
                margin: '10px 0 0 0',
                types: [this.getSetting('type')],
                attribute: this.getSetting('groupByField'),
                context: this.getContext(),
                storeConfig: {
                    pageSize: this.getSetting('pageSize'),
                    filters: this._getQueryFilters()
                },
                cardConfig: {
                    editable: true,
                    showIconMenus: true,
                    fields: this.getSetting('fields').split(',')
                },
                columnConfig: {
                    cardLimit: this.getSetting('pageSize'),
                    enableInfiniteScroll: this.getContext().isFeatureEnabled('S64257_ENABLE_INFINITE_SCROLL_ALL_BOARDS')
                },
                loadMask: true
            });
        },

        getSettingsFields: function() {
            return Rally.apps.board.Settings.getFields(this.getContext());
        },

        onTimeboxScopeChange: function() {
            this.callParent(arguments);
            this.down('rallycardboard').refresh({
                storeConfig: {
                    filters: this._getQueryFilters()
                }
            });
        },

        _getQueryFilters: function() {
            var queries = [];
            if (this.getSetting('query')) {
                queries.push(Rally.data.QueryFilter.fromQueryString(this.getSetting('query')));
            }
            if (this.getContext().getTimeboxScope()) {
                queries.push(this.getContext().getTimeboxScope().getQueryFilter());
            }

            return queries;
        }
    });
})();

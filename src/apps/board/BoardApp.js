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
                fields: 'FormattedID,Name,Owner',
                query: '',
                order: 'Rank'
            }
        },

        initComponent: function() {
            if (!this.getContext().isFeatureEnabled('S64257_ENABLE_INFINITE_SCROLL_ALL_BOARDS')) {
                this.defaultSettings.pageSize = 25;
            }

            this.callParent(arguments);
        },

        launch: function() {
            this.add({
                xtype: 'rallycardboard',
                margin: '10px 0 0 0',
                types: [this.getSetting('type')],
                attribute: this.getSetting('groupByField'),
                context: this.getContext(),
                storeConfig: {
                    // pageSize config can be removed when we remove ENABLE_INFINITE_SCROLL_ALL_BOARDS toggle, because we can use the default value
                    pageSize: this.getContext().isFeatureEnabled('S64257_ENABLE_INFINITE_SCROLL_ALL_BOARDS') ? 15 : this.getSetting('pageSize'),
                    filters: this._getQueryFilters()
                },
                cardConfig: {
                    editable: true,
                    showIconMenus: true,
                    fields: this.getSetting('fields').split(',')
                },
                columnConfig: {
                    enableInfiniteScroll: this.getContext().isFeatureEnabled('S64257_ENABLE_INFINITE_SCROLL_ALL_BOARDS')
                },
                loadMask: true
            });
        },

        getSettingsFields: function() {
            var settingsFields = Rally.apps.board.Settings.getFields(this.getContext());

            if (this.getContext().isFeatureEnabled('S64257_ENABLE_INFINITE_SCROLL_ALL_BOARDS')) {
                // when ENABLE_INFINITE_SCROLL_ALL_BOARDS toggle is removed,
                // the pageSize setting can be removed from the Rally.apps.board.Settings.getFields method
                // and this filter can be removed.
                return _.filter(settingsFields, function(field) {
                    return field.name !== 'pageSize';
                });
            }

            return settingsFields;
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

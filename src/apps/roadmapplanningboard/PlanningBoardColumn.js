(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.PlanningBoardColumn', {
        extend: 'Rally.ui.cardboard.Column',
        alias: 'widget.planningboardcolumn',

        mixins: {
            maskable: 'Rally.ui.mask.Maskable'
        },
        requires: [
            'Rally.apps.roadmapplanningboard.plugin.OrcaColumnDropController',
            'Rally.ui.filter.view.FilterButton',
            'Rally.ui.filter.view.CustomQueryFilter'
        ],

        queryFilter: null,

        config: {
            filterable: false,
            baseQueryFilter: null,
            storeConfig: {
                fetch: ['Value', 'FormattedID', 'Owner', 'Name', 'PreliminaryEstimate', 'DisplayColor']
            },
            dropControllerConfig: {
                ptype: 'orcacolumndropcontroller'
            },
            moreItemsConfig: {
                hidden: true,
                token: '/portfolioitems'
            },
            cardConfig: {
                showIconsAndHighlightBorder: true,
                showPlusIcon: false,
                showColorIcon: true,
                showGearIcon: true,
                showReadyIcon: false,
                showBlockedIcon: false,
                showEditMenuItem: true,
                showCopyMenuItem: false,
                showSplitMenuItem: false,
                showDeleteMenuItem: true
            }
        },

        constructor: function (config) {
            this.mergeConfig(config);
            this.config.storeConfig.autoLoad = !this.filterable;
            if (this.config.baseFilter && !this.config.baseFilter._createQueryString) {
                this.config.baseFilter = this._createBaseFilter(this.config.baseFilter);
            }
            this.callParent([this.config]);
        },

        _createBaseFilter: function (bf) {
            var baseFilter;
            if (Ext.isArray(bf)) {
                _.each(bf, function (filter) {
                    if (baseFilter) {
                        baseFilter = baseFilter.and(new Rally.data.QueryFilter.fromExtFilter(filter));
                    } else {
                        baseFilter = new Rally.data.QueryFilter.fromExtFilter(filter);
                    }
                }, this);
            } else {
                baseFilter = new Rally.data.QueryFilter(bf);
            }
            return baseFilter;
        },

        initComponent: function () {
            if (this.filterable) {
                this.filterButton = this._createFilterButton();
            }

            this.callParent(arguments);

            return this.on('beforerender', function () {
                var cls;

                cls = 'planning-column';
                this.getContentCell().addCls(cls);
                return this.getColumnHeaderCell().addCls(cls);
            }, this, {
                single: true
            });
        },

        _createFilterButton: function () {
            var context = this.context || Rally.environment.getContext();
            return Ext.create('Rally.ui.filter.view.FilterButton', {
                cls: 'medium columnfilter',
                stateful: true,
                stateId: context.getScopedStateId('filter' + this.getColumnIdentifier()),
                listeners: {
                    filter: {
                        fn: this._initialFilter,
                        single: true,
                        scope: this
                    }
                },
                items: this._getFilterItems()
            });
        },

        isMatchingRecord: function () {
            return true;
        },

        _getProgressBarHtml: function () {
            return '<div></div>';
        },

        findCardInfo: function (searchCriteria, includeHiddenCards) {
            var card, index, _i, _len, _ref;

            searchCriteria = searchCriteria.get && searchCriteria.getId() ? searchCriteria.getId() : searchCriteria;
            _ref = this.getCards(includeHiddenCards);
            for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
                card = _ref[index];
                if (card.getRecord().getId() === searchCriteria || card.getEl() === searchCriteria || card.getEl() === Ext.get(searchCriteria)) {
                    return {
                        record: card.getRecord(),
                        index: index,
                        card: card
                    };
                }
            }
            return null;
        },

        destroy: function () {
            var plugin, _i, _len, _ref;

            _ref = this.plugins;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                plugin = _ref[_i];
                if (plugin !== null) {
                    plugin.destroy();
                }
            }
            return this.callParent(arguments);
        },

        drawHeader: function () {
            this.callParent(arguments);

            if (this.filterable) {
                this.getHeaderTitle().insert(0, this.filterButton);
            }
        },

        getColumnIdentifier: function () {
            Ext.Error.raise('Need to override this to ensure unique identifier for persistence');
        },

        _getFilterItems: function () {
            return [
                {
                    xtype: 'rallycustomqueryfilter',
                    filterHelpId: 194
                }
            ];
        },

        getStoreFilter: function (model) {
            var filter = this.baseFilter;

            if (this.filterable && this.queryFilter && this.queryFilter !== []) {
                if (filter) {
                    filter = filter.and(this.queryFilter);
                } else {
                    filter = this.queryFilter;
                }
            }

            return filter;
        },

        _initialFilter: function (component, filters) {
            component.on('filter', this._onFilter, this);
            this._applyFilter(filters);
            this.config.storeConfig.autoLoad = true;
            this.loadStore();
        },

        _onFilter: function (component, filters) {
            this._applyFilter(filters);
            this.refresh(this.config);
        },

        _applyFilter: function (filters) {
            this.queryFilter = filters[0];

            if (this.queryFilter) {
                this.filterButton.removeCls('secondary');
                this.filterButton.addCls('primary');
            } else {
                this.filterButton.removeCls('primary');
                this.filterButton.addCls('secondary');
            }
        }
    });

})();

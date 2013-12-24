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
        queryFilterKey: 'page.roadmap.queryfilter.',

        config: {
            filterable: false,
            baseQueryFilter: null,
            storeConfig: {
                fetch: ['Value', 'FormattedID', 'Owner', 'Name', 'PreliminaryEstimate', 'DisplayColor']
            },
            dropControllerConfig: {
                ptype: 'orcacolumndropcontroller'
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
                showDeleteMenuItem: true,
                showAddChildMenuItem: false,
                showRankMenuItems: false
            }
        },

        constructor: function (config) {
            this.mergeConfig(config);
            this.context = this.context || Rally.environment.getContext();
            if(!this.config.context) {
                this.config.context = this.context;
            }
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
                this.queryFilterKey = this.queryFilterKey + this.getColumnIdentifier() + '.' + this.context.getWorkspace().ObjectID;
                this.filterButton = this._createFilterButton();
                Rally.data.ModelFactory.getModel({
                    type: 'Preference',
                    success: function (model) {
                        this.queryFilterModel = model;
                        this._initialFilter();
                    },
                    scope: this
                });
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
            return Ext.create('Rally.ui.filter.view.FilterButton', {
                cls: 'medium columnfilter',
                items: [
                    {
                        xtype: 'rallycustomqueryfilter',
                        filterHelpId: 194,
                        listeners: {
                            beforerender: {
                                fn: this._setQueryFilterValue,
                                single: true,
                                scope: this
                            }
                        }
                    }
                ]
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

        _initialFilter: function () {
            this.filterButton.on('filter', this._onFilter, this);

            //get the preference and convert to a filter
            this._findPreference(function (preference) {
                if (preference && preference.get('Value')) {
                    this.queryFilter = Rally.data.QueryFilter.fromQueryString(preference.get('Value'));
                    //need to set value on the custom query filter this.queryFilter
                    this._applyFilter();
                } else {
                    this.queryFilter = null;
                }
                this.config.storeConfig.autoLoad = true;
                this.loadStore();
            });
        },

        _onFilter: function (component, filters) {
            this.queryFilter = filters[0];
            this._saveQueryFilter();
            this._applyFilter();
            this.refresh(this.config);
        },

        _setQueryFilterValue: function (component, options) {
            if (this.queryFilter) {
                component.setValue(this.queryFilter.toString());
            } else {
                component.setValue('');
            }
        },

        _applyFilter: function () {
            if (this.queryFilter) {
                this.filterButton.removeCls('secondary');
                this.filterButton.addCls('primary');
            } else {
                this.filterButton.removeCls('primary');
                this.filterButton.addCls('secondary');
            }
        },

        _saveQueryFilter: function () {
            if (this.filterable) {
                this._findPreference(function (preference) {
                    var value = this.queryFilter ? this.queryFilter.toString() : '';
                    if (preference) {
                        preference.set('Value', value);
                    } else {
                        preference = Ext.create(this.queryFilterModel, {
                            Name: this.queryFilterKey,
                            User: '/user/' + this.context.getUser().ObjectID,
                            Project: 'null',
                            Workspace: '/workspace/' + this.context.getWorkspace().ObjectID,
                            Value: value
                        });
                    }
                    preference.save({
                        success: function (preference) {
                            this.publish(Rally.Message.preferenceUpdated, preference);
                        },
                        scope: this
                    });
                });
            }
        },

        _findPreference: function (callback) {
            this.queryFilterModel.find({
                filters: [
                    { property: 'Name', value: this.queryFilterKey },
                    { property: 'User', value: '/user/' + this.context.getUser().ObjectID }
                ],
                callback: callback,
                scope: this
            });
        }
    });
})();

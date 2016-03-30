(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.common.PortfolioItemsGridBoardApp', {
        extend: 'Rally.app.GridBoardApp',

        requires: [
            'Rally.data.Ranker',
            'Rally.ui.cardboard.plugin.CollapsibleColumns',
            'Rally.ui.cardboard.plugin.FixedHeader',
            'Rally.ui.gridboard.plugin.GridBoardInlineFilterControl',
            'Rally.ui.gridboard.plugin.GridBoardSharedViewControl',
            'Rally.ui.notify.Notifier'
        ],

        constructor: function(config){
            var defaultConfig = {
                piTypePickerConfig: {
                    renderInGridHeader: false
                }
            };

            this.callParent([Ext.Object.merge(defaultConfig, config)]);
        },

        initComponent: function(){
            this.callParent(arguments);
            this.addCls('portfolio-items-grid-board-app');
        },

        getAddNewConfig: function () {
            var config = {};
            if (this.getContext().isFeatureEnabled('S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN')) {
                config.margin = 0;
            }

            return _.merge(this.callParent(arguments), config);
        },

        addGridBoard: function(){
            if (this.gridboard && this.piTypePicker && this.piTypePicker.rendered) {
                var parent = this.piTypePicker.up();
                if(parent && parent.remove){
                    parent.remove(this.piTypePicker, false);
                }
            }
            this.callParent(arguments);
        },

        launch: function () {
            if (Rally.environment.getContext().getSubscription().isModuleEnabled('Rally Portfolio Manager')) {
                this.callParent(arguments);
            } else {
                this.add({
                    xtype: 'container',
                    html: '<div class="rpm-turned-off" style="padding: 50px; text-align: center;">You do not have RPM enabled for your subscription</div>'
                });

                this.publishComponentReady();
            }
        },

        loadModelNames: function () {
            return this._createPITypePicker().then({
                success: function (selectedType) {
                    this.currentType = selectedType;
                    return [selectedType.get('TypePath')];
                },
                scope: this
            });
        },

        getGridBoardCustomFilterControlConfig: function () {
            var context = this.getContext(),
                skinnyFilter = !!context.isFeatureEnabled('F10466_INLINE_FILTER_UI_ENHANCEMENTS');

            if (context.isFeatureEnabled('S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN')) {
                return {
                    ptype: 'rallygridboardinlinefiltercontrol',
                    inline: skinnyFilter,
                    skinny: skinnyFilter,
                    inlineFilterButtonConfig: {
                        stateful: true,
                        stateId: context.getScopedStateId('portfolio-items-inline-filter'),
                        legacyStateIds: [
                            this.getScopedStateId('owner-filter'),
                            this.getScopedStateId('custom-filter-button')
                        ],
                        filterChildren: true,
                        modelNames: this.modelNames,
                        inlineFilterPanelConfig: {
                            quickFilterPanelConfig: {
                                defaultFields: [
                                    'ArtifactSearch',
                                    'Owner'
                                ],
                                addQuickFilterConfig: {
                                    blackListFields: ['PortfolioItemType', 'ModelType'],
                                    whiteListFields: ['Milestones', 'Tags']
                                }
                            },
                            advancedFilterPanelConfig: {
                                advancedFilterRowsConfig: {
                                    propertyFieldConfig: {
                                        blackListFields: ['PortfolioItemType'],
                                        whiteListFields: ['Milestones', 'Tags']
                                    }
                                }
                            }
                        }
                    }
                };
            }

            return {
                blackListFields: ['PortfolioItemType'],
                whiteListFields: ['Milestones']
            };
        },

        getSharedViewConfig: function() {
            var context = this.getContext();
            if (context.isFeatureEnabled('S105843_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_PORTFOLIO_ITEMS_AND_KANBAN')) {
                return {
                    ptype: 'rallygridboardsharedviewcontrol',
                    sharedViewConfig: {
                        stateful: true,
                        stateId: this.getContext().getScopedStateId('portfolio-items-shared-view'),
                        defaultViews: _.map(this._getDefaultViews(), function (view) {
                            Ext.apply(view, {
                                Value: Ext.JSON.encode(view.Value, true)
                            });
                            return view;
                        }, this),
                        enableUrlSharing: this.isFullPageApp !== false,
                        suppressViewNotFoundNotification: this._suppressViewNotFoundNotification
                    },
                    additionalFilters: [{
                        property: 'Value',
                        operator: 'contains',
                        value: '"piTypePicker":"' + this.piTypePicker.getRecord().get('_refObjectUUID') + '"'
                    }]
                };
            }

            return {};
        },

        getFieldPickerConfig: function () {
            return _.merge(this.callParent(arguments), {
                boardFieldBlackList: ['Predecessors', 'Successors']
            });
        },

        getGridBoardConfig: function () {
            return _.merge(this.callParent(arguments), {
                listeners: {
                    viewchange: this._onViewChange,
                    scope: this
                },
                sharedViewAdditionalCmps: [this.piTypePicker]
            });
        },

        getCardBoardColumns: function () {
            return this._getStates().then({
                success: function (states) {
                    return this._buildColumns(states);
                },
                scope: this
            });
        },

        _buildColumns: function (states) {
            if (!states.length) {
                return undefined;
            }

            var columns = [
                {
                    columnHeaderConfig: {
                        headerTpl: 'No Entry'
                    },
                    value: null,
                    plugins: ['rallycardboardcollapsiblecolumns'].concat(this.getCardBoardColumnPlugins(null))
                }
            ];

            return columns.concat(_.map(states, function (state) {
                return {
                    value: state.get('_ref'),
                    wipLimit: state.get('WIPLimit'),
                    enableWipLimit: true,
                    columnHeaderConfig: {
                        record: state,
                        fieldToDisplay: 'Name',
                        editable: false
                    },
                    plugins: ['rallycardboardcollapsiblecolumns'].concat(this.getCardBoardColumnPlugins(state))
                };
            }, this));
        },

        _getStates: function () {
            var deferred = new Deft.Deferred();
            Ext.create('Rally.data.wsapi.Store', {
                model: Ext.identityFn('State'),
                context: this.getContext().getDataContext(),
                autoLoad: true,
                fetch: ['Name', 'WIPLimit', 'Description'],
                filters: [
                    {
                        property: 'TypeDef',
                        value: this.currentType.get('_ref')
                    },
                    {
                        property: 'Enabled',
                        value: true
                    }
                ],
                sorters: [
                    {
                        property: 'OrderIndex',
                        direction: 'ASC'
                    }
                ],
                listeners: {
                    load: function (store, records) {
                        deferred.resolve(records);
                    }
                }
            });
            return deferred.promise;
        },

        _getDefaultViews: function() {
            if (this.toggleState === 'grid'){
                var rankColumnDataIndex = this.getContext().getWorkspace().WorkspaceConfiguration.DragDropRankingEnabled ?
                        Rally.data.Ranker.RANK_FIELDS.DND : Rally.data.Ranker.RANK_FIELDS.MANUAL,
                    defaultViewName = this.piTypePicker.getRawValue() + ' Default',
                    columns = [
                        { dataIndex: rankColumnDataIndex},
                        { dataIndex: 'Name'},
                        { dataIndex: 'State'},
                        { dataIndex: 'PercentDoneByStoryCount'},
                        { dataIndex: 'PlannedStartDate'},
                        { dataIndex: 'PlannedEndDate'},
                        { dataIndex: 'Project'}
                    ],
                    ordinalValue = this.piTypePicker.getRecord().get('Ordinal') + 1;

                if (ordinalValue === 1) {
                    columns.push({ dataIndex: 'Release'});
                }

                return [{
                    Name: defaultViewName,
                    identifier: ordinalValue,
                    Value: {
                        toggleState: 'grid',
                        columns: columns,
                        sorters:[{ property: rankColumnDataIndex, direction: 'ASC'}]
                    }
                }];
            }

            return [];
        },

        getCardBoardColumnPlugins: function (state) {
            return [];
        },

        getCardConfig: function () {
            return {};
        },

        getCardBoardConfig: function (options) {
            options = options || {};
            var currentTypePath = this.currentType.get('TypePath');
            var filters = [];

            if (this.getSetting('query')) {
                try {
                    filters.push(Rally.data.QueryFilter.fromQueryString(this.getSetting('query')));
                } catch (e) {
                    Rally.ui.notify.Notifier.showError({ message: e.message });
                }
            }

            return {
                attribute: 'State',
                cardConfig: _.merge({
                    editable: true,
                    showColorIcon: true
                }, this.getCardConfig()),
                columnConfig: {
                    xtype: 'rallycardboardcolumn',
                    enableWipLimit: true,
                    fields: (this.getSetting('fields') || '').split(',')
                },
                columns: options.columns,
                ddGroup: currentTypePath,
                listeners: {
                    load: this.publishComponentReady,
                    cardupdated: this._publishContentUpdatedNoDashboardLayout,
                    scope: this
                },
                plugins: [{ ptype: 'rallyfixedheadercardboard' }],
                storeConfig: {
                    filters: filters,
                    context: this.getContext().getDataContext()
                }
            };
        },

        getGridStoreConfig: function () {
            return _.merge({}, this.gridStoreConfig, { models: this.piTypePicker.getAllTypeNames() });
        },

        _createPITypePicker: function () {
            if (this.piTypePicker && this.piTypePicker.destroy) {
                this.piTypePicker.destroy();
            }
            var deferred = new Deft.Deferred();
            var piTypePickerConfig = {
                preferenceName: this.getStateId('typepicker'),
                fieldLabel: '', // delete this when removing PORTFOLIO_ITEM_TREE_GRID_PAGE_OPT_IN toggle. Can't delete these from PI Combobox right now or GUI tests fail in old PI page
                labelWidth: 0,  // delete this when removing PORTFOLIO_ITEM_TREE_GRID_PAGE_OPT_IN toggle. Can't delete these from PI Combobox right now or GUI tests fail in old PI page
                value: this.getSetting('type'),
                context: this.getContext(),
                listeners: {
                    change: this._onTypeChange,
                    ready: {
                        fn: function (picker) {
                            deferred.resolve(picker.getSelectedType());
                        },
                        single: true
                    },
                    scope: this
                }
            };

            if(!this.config.piTypePickerConfig.renderInGridHeader){
                piTypePickerConfig.renderTo = Ext.query('#content .titlebar .dashboard-timebox-container')[0];
            }

            this.piTypePicker = Ext.create('Rally.ui.combobox.PortfolioItemTypeComboBox', piTypePickerConfig);

            if(this.config.piTypePickerConfig.renderInGridHeader){
              this.on('gridboardadded', function() {
                var headerContainer = this.gridboard.getHeader().getLeft();
                headerContainer.add(this.piTypePicker);
              });
            }

            return deferred.promise;
        },

        _onTypeChange: function (picker) {
            Rally.ui.notify.Notifier.hide();
            var newType = picker.getSelectedType();

            if (this._pickerTypeChanged(picker)) {
                this._suppressViewNotFoundNotificationWhenPiTypeChanges();

                this.currentType = newType;
                this.modelNames = [newType.get('TypePath')];
                this.gridboard.fireEvent('modeltypeschange', this.gridboard, [newType]);
            }
        },

        _suppressViewNotFoundNotificationWhenPiTypeChanges: function() {
            var plugin = _.find(this.gridboard.plugins, {ptype: 'rallygridboardsharedviewcontrol'});
            if (plugin && plugin.controlCmp && plugin.controlCmp.getSharedViewParam()){
                this._suppressViewNotFoundNotification = true;
            }
        },

        _onViewChange: function() {
            Rally.ui.notify.Notifier.hide();
            this.loadGridBoard();
        },

        _pickerTypeChanged: function(picker){
            var newType = picker.getSelectedType();
            return newType && this.currentType && newType.get('_ref') !== this.currentType.get('_ref');
        },

        _publishContentUpdatedNoDashboardLayout: function () {
            this.fireEvent('contentupdated', { dashboardLayout: false });
        },

        onDestroy: function() {
            this.callParent(arguments);
            if(this.piTypePicker) {
                this.piTypePicker.destroy();
                delete this.piTypePicker;
            }
        }
    });
})();

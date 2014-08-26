(function () {
    var Ext = window.Ext4 || window.Ext;

    /**
     * PI Kanban Board App
     * Displays a cardboard and a type selector. Board shows States for the selected Type.
     */
    Ext.define('Rally.apps.portfoliokanban.PortfolioKanbanApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.apps.portfoliokanban.PortfolioKanbanCard',
            'Rally.apps.portfoliokanban.PortfolioKanbanPolicy',
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.ui.gridboard.plugin.BoardPolicyDisplayable',
            'Rally.ui.filter.view.OwnerPillFilter',
            'Rally.ui.filter.view.TagPillFilter',
            'Rally.ui.gridboard.GridBoard',
            'Rally.ui.cardboard.plugin.CollapsibleColumns',
            'Rally.ui.cardboard.plugin.ColumnPolicy',
            'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl',
            'Rally.ui.cardboard.plugin.FixedHeader',
            'Rally.ui.cardboard.Column',
            'Rally.ui.cardboard.CardBoard',
            'Rally.ui.cardboard.Card',
            'Rally.data.QueryFilter',
            'Rally.ui.notify.Notifier',
            'Rally.ui.AddNew',
            'Rally.ui.LeftRight',
            'Rally.util.Help',
            'Rally.util.Test',
            'Deft.Deferred'
        ],
        autoScroll: false,
        appName: 'Portfolio Kanban',

        cls: 'portfolio-kanban',

        config: {
            defaultSettings: {
                fields: 'Discussion,PercentDoneByStoryCount,UserStories'
            }
        },

        mixins: [
          "Rally.clientmetrics.ClientMetricsRecordable"
        ],

        clientMetrics: [
            {
                method: '_showHelp',
                description: 'portfolio-kanban-show-help'
            }
        ],

        constructor: function(config) {
            if (this._milestonesAreEnabled()) {
                this.config.defaultSettings.fields += ',Milestones';
            }

            this.callParent([config]);
        },

        launch: function () {
            if (!Rally.environment.getContext().getSubscription().isModuleEnabled('Rally Portfolio Manager')) {
                this.add({
                    xtype: 'container',
                    html: '<div class="rpm-turned-off" style="padding: 50px; text-align: center;">You do not have RPM enabled for your subscription</div>'
                });

                this._publishContentUpdated();

                return;
            }

            this._createPITypePicker().then({
                success: function (currentType) {
                    this.currentType = currentType;
                    this._loadCardboard();
                },
                scope: this
            });
        },

        _createPITypePicker: function () {
            if (this.piTypePicker) {
                this.piTypePicker.destroy();
            }

            var deferred = new Deft.Deferred();

            this.piTypePicker = Ext.create('Rally.ui.combobox.PortfolioItemTypeComboBox', {
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
            });

            return deferred.promise;
        },

        getSettingsFields: function () {
            return [
                {
                    type: 'project'
                },
                {
                    type: 'query',
                    config: {
                        plugins: [
                            {
                                ptype: 'rallyhelpfield',
                                helpId: 271
                            },
                            'rallyfieldvalidationui'
                        ]
                    }
                }
            ];
        },

        onDestroy: function () {
            if (this._percentDonePopover) {
                this._percentDonePopover.destroy();
                delete this._percentDonePopover;
            }

            this.callParent(arguments);
        },

        _drawHeader: function () {
            var header = this.gridboard.getHeader();

            if (header) {
                header.getRight().add([
                    this._buildHelpComponent(),
                    this.piTypePicker,
                    this._buildFilterInfo()
                ]);
            }
        },

        _loadCardboard: function (policyPluginCmpCfg) {
            this._loadStates({
                success: function (states) {
                    var columns = this._createColumns(states, policyPluginCmpCfg);
                    if (this.rendered) {
                        this._drawCardboard(columns);
                    } else {
                        this.on('afterrender', Ext.bind(this._drawCardboard, this, [columns]), this, {single: true});
                    }
                },
                scope: this
            });

        },

        /**
         * @private
         * We need the States of the selected Portfolio Item Type to know what columns to show.
         * Whenever the type changes, reload the states to redraw the cardboard.
         * @param options
         * @param options.success called when states are loaded
         * @param options.scope the scope to call success with
         */
        _loadStates: function (options) {
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
                        if (options.success) {
                            options.success.call(options.scope || this, records);
                        }
                    }
                }
            });

        },

        /**
         * Given a set of columns, build a cardboard component. Otherwise show an empty message.
         * @param columns
         */
        _drawCardboard: function (columns) {
            if (!this.rendered) {
                this.on('afterrender', Ext.bind(this._drawCardboard, this, [columns]), this, {single: true});
                return;
            }

            this._showColumns(columns);

            if (!columns || columns.length === 0) {
                this._showNoColumns();
                this._onBoardLoad();
            }
        },

        _createFilterItem: function(typeName, config) {
            return Ext.apply({
                xtype: typeName,
                margin: '-15 0 5 0',
                showPills: true,
                showClear: true
            }, config);
        },


        _showColumns: function (columns) {
            var filters = [{
                property: 'PortfolioItemType',
                value: this.currentType.get('_ref')
            }];

            if (this.getSetting('query')) {
                try {
                    filters.push(Rally.data.QueryFilter.fromQueryString(this.getSetting('query')));
                } catch (e) {
                    Rally.ui.notify.Notifier.showError({
                        message: e.message
                    });
                }
            }

            var currentTypePath = this.currentType.get('TypePath');

            if (this.gridboard) {
                this.gridboard.modelNames = [currentTypePath];

                if (this.cardboard.filterCollection) {
                    this.cardboard.filterCollection.clearAllFilters();
                }

                this.cardboard.refresh({
                    columns: columns,
                    ddGroup: currentTypePath,
                    types: [currentTypePath],
                    storeConfig: {
                        filters: filters,
                        context: this.getContext().getDataContext()
                    }
                });
            } else {
                this.gridboard = Ext.create('Rally.ui.gridboard.GridBoard', {
                    itemId: 'gridboard',
                    toggleState: 'board',
                    modelNames: [currentTypePath],
                    context: this.getContext(),
                    addNewPluginConfig: {
                        style: {
                            'float': 'left'
                        }
                    },
                    plugins: [
                        'rallygridboardaddnew',
                        {
                            ptype: 'rallygridboardcustomfiltercontrol',
                            filterChildren: false,
                            filterControlConfig: {
                                blackListFields: ['PortfolioItemType', 'State'],
                                whiteListFields: [this._milestonesAreEnabled() ? 'Milestones' : ''],
                                margin: '3 9 3 30',
                                modelNames: [currentTypePath],
                                stateful: true,
                                stateId: this.getContext().getScopedStateId('portfolio-kanban-custom-filter-button')
                            },
                            showOwnerFilter: true,
                            ownerFilterControlConfig: {
                                stateful: true,
                                stateId: this.getContext().getScopedStateId('portfolio-kanban-owner-filter')
                            }
                        },
                        {
                            ptype: 'rallygridboardfieldpicker',
                            boardFieldBlackList: [
                                'AcceptedLeafStoryCount',
                                'AcceptedLeafStoryPlanEstimateTotal',
                                'DirectChildrenCount',
                                'LastUpdateDate',
                                'LeafStoryCount',
                                'LeafStoryPlanEstimateTotal',
                                'UnEstimatedLeafStoryCount'
                            ],
                            boardFieldDefaults: this.getSetting('fields').split(','),
                            headerPosition: 'left'
                        },
                        {
                            ptype: 'rallyboardpolicydisplayable',
                            pluginId: 'boardPolicyDisplayable',
                            prefKey: 'piKanbanPolicyChecked',
                            checkboxConfig: {
                                boxLabel: 'Show Policies',
                                margin: '2 5 5 5'
                            }
                        }
                    ],
                    listeners: {
                        toggle: this._gridBoardToggle,
                        scope: this
                    },
                    cardBoardConfig: {
                        attribute: 'State',
                        cardConfig: {
                            xtype: 'rallyportfoliokanbancard',
                            editable: true,
                            showColorIcon: true
                        },
                        columnConfig: {
                            xtype: 'rallycardboardcolumn',
                            enableWipLimit: true
                        },
                        columns: columns,
                        ddGroup: currentTypePath,
                        listeners: {
                            load: this._onBoardLoad,
                            cardupdated: this._publishContentUpdatedNoDashboardLayout,
                            scope: this
                        },
                        loadDescription: 'Portfolio Kanban',
                        plugins: [{ ptype: 'rallyfixedheadercardboard' }],
                        storeConfig: {
                            filters: filters,
                            context: this.context.getDataContext()
                        }
                    },
                    height: this.getHeight()
                });

                this.add(this.gridboard);
                this._drawHeader();
            }
        },

        setHeight: function(height) {
            this.callParent(arguments);
            if(this.gridboard) {
                this.gridboard.setHeight(height);
            }
        },

        _onTypeChange: function (picker) {
            var policyCfg,
                policyPlugin,
                newType = picker.getSelectedType();

            if (newType && this.currentType && newType.get('_ref') !== this.currentType.get('_ref')) {
                this.currentType = newType;
                this.gridboard.fireEvent('modeltypeschange', this.gridboard, [newType]);
                policyPlugin = this.gridboard.getPlugin('boardPolicyDisplayable');
                if (policyPlugin) {
                    policyCfg = {
                        hidden: !policyPlugin.isChecked()
                    };
                }
                this._loadCardboard(policyCfg);
            }
        },

        _gridBoardToggle: function (toggleState, gridOrBoard) {
            this.cardboard = toggleState === 'board' ? gridOrBoard : null;
        },

        getMaskId: function () {
            return 'btid-portfolio-kanban-board-load-mask-' + this.id;
        },

        _onBoardLoad: function (cardboard) {
            this._publishContentUpdated();
            Rally.environment.getMessageBus().publish(Rally.Message.piKanbanBoardReady);
            this.recordComponentReady();
        },

        _showNoColumns: function () {
            this.add({
                xtype: 'container',
                cls: 'no-type-text',
                html: '<p>This Type has no states defined.</p>'
            });
            this._publishContentUpdated();
        },

        /**
         * @private
         * @return columns for the cardboard, as a map with keys being the column name.
         */
        _createColumns: function (states, policyPluginCmpCfg) {
            if (!states.length) {
                return undefined;
            }

            var defaultColumnPolicyPlugin = {
                ptype: 'rallycolumnpolicy',
                policyCmpConfig: Ext.merge({
                    xtype: 'rallyportfoliokanbanpolicy',
                    hidden: true,
                    title: 'Exit Policy'
                }, policyPluginCmpCfg || {})
            };

            var columns = [
                {
                    columnHeaderConfig: {
                        headerTpl: 'No Entry'
                    },
                    value: null,
                    plugins: [defaultColumnPolicyPlugin, 'rallycardboardcollapsiblecolumns']
                }
            ];

            Ext.Array.each(states, function (state) {
                var stateColumnPolicyPlugin = Ext.merge({}, defaultColumnPolicyPlugin);
                stateColumnPolicyPlugin.policyCmpConfig.stateRecord = state;

                columns.push({
                    value: state.get('_ref'),
                    wipLimit: state.get('WIPLimit'),
                    enableWipLimit: true,
                    columnHeaderConfig: {
                        record: state,
                        fieldToDisplay: 'Name',
                        editable: false
                    },
                    plugins: [stateColumnPolicyPlugin, 'rallycardboardcollapsiblecolumns']
                });
            }, this);

            return columns;
        },

        _buildHelpComponent: function (config) {
            return this.isFullPageApp ? null : Ext.create('Ext.Component', Ext.apply({
                cls: 'help-field ' + Rally.util.Test.toBrowserTestCssClass('portfolio-kanban-help-container'),
                renderTpl: Rally.util.Help.getIcon({
                    id: 265
                })
            }, config));
        },

        _buildFilterInfo: function () {
            this.filterInfo = this.isFullPageApp ? null : Ext.create('Rally.ui.tooltip.FilterInfo', {
                projectName: this.getSetting('project') && this.getContext().get('project').Name || 'Following Global Project Setting',
                scopeUp: this.getSetting('projectScopeUp'),
                scopeDown: this.getSetting('projectScopeDown'),
                query: this.getSetting('query')
            });

            return this.filterInfo;
        },

        _publishContentUpdated: function () {
            this.fireEvent('contentupdated');
            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this);
            }
        },

        _publishContentUpdatedNoDashboardLayout: function () {
            this.fireEvent('contentupdated', {dashboardLayout: false});
        },

        _milestonesAreEnabled: function() {
            var context = this.getContext() ? this.getContext() : Rally.environment.getContext();
            return context.isFeatureEnabled('S70874_SHOW_MILESTONES_PAGE');
        }
    });
})();

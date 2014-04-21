(function () {
    var Ext = window.Ext4 || window.Ext;

    /**
     * PI Kanban Board App
     * Displays a cardboard and a type selector. Board shows States for the selected Type.
     */
    Ext.define('Rally.apps.portfoliokanban.PortfolioKanbanApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.data.util.PortfolioItemHelper',
            'Rally.apps.portfoliokanban.PortfolioKanbanCard',
            'Rally.apps.portfoliokanban.PortfolioKanbanPolicy',
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.ui.gridboard.GridBoard',
            'Rally.ui.cardboard.plugin.ColumnPolicy',
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
        layout: 'auto',
        appName: 'Portfolio Kanban',

        cls: 'portfolio-kanban',

        config: {
            defaultSettings: {
                fields: 'PercentDoneByStoryCount'
            }
        },

        clientMetrics: [
            {
                method: '_showHelp',
                description: 'portfolio-kanban-show-help'
            }
        ],

        items: [
            {
                xtype: 'rallyleftright',
                itemId: 'header'
            },
            {
                xtype: 'container',
                itemId: 'bodyContainer',
                width: '100%'
            }
        ],

        launch: function () {
            if (!Rally.environment.getContext().getSubscription().isModuleEnabled('Rally Portfolio Manager')) {
                this.down('#bodyContainer').add({
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
                    this._buildShowPolicies(),
                    this.piTypePicker,
                    this._buildFilterInfo()
                ]);
            }
        },

        _loadCardboard: function () {
            this._loadStates({
                success: function (states) {
                    var columns = this._createColumns(states);
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
                        context: this.context.getDataContext()
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
                            ptype: 'rallygridboardfieldpicker',
                            boardFieldBlackList: [
                                'ObjectID',
                                'Description',
                                'DisplayColor',
                                'FormattedID',
                                'Name',
                                'Notes',
                                'Ready',
                                'AcceptedLeafStoryCount',
                                'AcceptedLeafStoryPlanEstimateTotal',
                                'DirectChildrenCount',
                                'LeafStoryCount',
                                'LeafStoryPlanEstimateTotal',
                                'Rank',
                                'DragAndDropRank',
                                'UnEstimatedLeafStoryCount',
                                'CreationDate',
                                'Subscription',
                                'Workspace',
                                'Changesets',
                                'Discussion',
                                'LastUpdateDate',
                                'Owner'
                            ],
                            boardFieldDefaults: this.getSetting('fields').split(','),
                            headerPosition: 'left'
                        }
                    ],
                    listeners: {
                        toggle: this._gridBoardToggle,
                        scope: this
                    },
                    cardBoardConfig: {
                        attribute: 'State',
                        columns: columns,
                        ddGroup: currentTypePath,
                        cls: 'cardboard',
                        columnConfig: {
                            xtype: 'rallycardboardcolumn',
                            additionalFetchFields: ['Discussion'],
                            cardLimit: 50,
                            enableWipLimit: true,
                            enableInfiniteScroll: this.getContext().isFeatureEnabled('S64257_ENABLE_INFINITE_SCROLL_ALL_BOARDS')
                        },
                        cardConfig: {
                            xtype: 'rallyportfoliokanbancard',
                            editable: true,
                            fields: Rally.apps.portfoliokanban.PortfolioKanbanCard.defaultFields.concat('Discussion'),
                            showColorIcon: true
                        },
                        storeConfig: {
                            filters: filters,
                            context: this.context.getDataContext()
                        },
                        listeners: {
                            load: this._onBoardLoad,
                            cardupdated: this._publishContentUpdatedNoDashboardLayout,
                            scope: this
                        },
                        loadDescription: 'Portfolio Kanban',
                        loadMask: false
                    }
                });

                this.down('#bodyContainer').add(this.gridboard);
                this._drawHeader();
            }
        },

        _onTypeChange: function (picker) {
            var newType = picker.getSelectedType();

            if (newType && this.currentType && newType.get('_ref') !== this.currentType.get('_ref')) {
                this.currentType = newType;
                this.gridboard.fireEvent('modeltypeschange', this.gridboard, [newType]);
                this._loadCardboard();
            }
        },

        _gridBoardToggle: function (toggleState, gridOrBoard) {
            this.cardboard = toggleState === 'board' ? gridOrBoard : null;
            this._renderPolicies();
        },

        getMaskId: function () {
            return 'btid-portfolio-kanban-board-load-mask-' + this.id;
        },

        _onBoardLoad: function (cardboard) {
            this._publishContentUpdated();
            Rally.environment.getMessageBus().publish(Rally.Message.piKanbanBoardReady);
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
        _createColumns: function (states) {
            if (!states.length) {
                return undefined;
            }

            var columns = [
                {
                    columnHeaderConfig: {
                        headerTpl: 'No Entry'
                    },
                    value: null,
                    plugins: [{
                        ptype: 'rallycolumnpolicy',
                        policyCmpConfig: {
                            xtype: 'rallyportfoliokanbanpolicy',
                            hidden: true,
                            title: 'Exit Policy'
                        }
                    }]
                }
            ];

            Ext.Array.each(states, function (state) {
                columns.push({
                    value: state.get('_ref'),
                    wipLimit: state.get('WIPLimit'),
                    enableWipLimit: true,
                    columnHeaderConfig: {
                        record: state,
                        fieldToDisplay: 'Name',
                        editable: false
                    },
                    plugins: [{
                        ptype: 'rallycolumnpolicy',
                        policyCmpConfig: {
                            xtype: 'rallyportfoliokanbanpolicy',
                            hidden: true,
                            stateRecord: state,
                            title: 'Exit Policy'
                        }
                    }]
                });
            });

            return columns;
        },

        _renderPolicies: function () {
            var showPoliciesCheckbox = this.down("#showPoliciesCheckbox");

            Ext.each(this.cardboard.getColumns(), function (column) {
                if (showPoliciesCheckbox.getValue()) {
                    column.fireEvent('showpolicy');
                } else {
                    column.fireEvent('hidepolicy');
                }
            });
        },

        _buildShowPolicies: function () {
            return Ext.widget('checkbox', {
                cls: 'showPolicies',
                itemId: 'showPoliciesCheckbox',
                fieldCls: 'showPoliciesCheckbox',
                boxLabel: "Show Policies",
                listeners: {
                    change: {
                        fn: this._renderPolicies,
                        scope: this
                    }
                }
            });

        },

        _buildHelpComponent: function (config) {
            return Ext.create('Ext.Component', Ext.apply({
                cls: 'help-field ' + Rally.util.Test.toBrowserTestCssClass('portfolio-kanban-help-container'),
                renderTpl: Rally.util.Help.getIcon({
                    id: 265
                })
            }, config));
        },

        _buildFilterInfo: function () {
            if (this.appContainer.panelDef.panelConfigs.hideFilterOnPortfolioKanban === 'true') {
                this.filterInfo = null;
            } else {
                this.filterInfo = Ext.create('Rally.ui.tooltip.FilterInfo', {
                    projectName: this.getSetting('project') && this.getContext().get('project').Name || 'Following Global Project Setting',
                    scopeUp: this.getSetting('projectScopeUp'),
                    scopeDown: this.getSetting('projectScopeDown'),
                    query: this.getSetting('query')
                });
            }

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
        }

    });
})();

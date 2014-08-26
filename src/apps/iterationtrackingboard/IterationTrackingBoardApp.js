(function () {
    var Ext = window.Ext4 || window.Ext;

    var defaultGridColumns = ['Name', 'ScheduleState', 'Blocked', 'PlanEstimate', 'TaskStatus', 'TaskEstimateTotal', 'TaskRemainingTotal', 'Owner', 'DefectStatus', 'Discussion'];

    /**
     * Iteration Tracking Board App
     * The Iteration Tracking Board can be used to visualize and manage your User Stories and Defects within an Iteration.
     */
    Ext.define('Rally.apps.iterationtrackingboard.IterationTrackingBoardApp', {
        extend: 'Rally.app.TimeboxScopedApp',
        requires: [
            'Rally.data.Ranker',
            'Rally.data.WsapiModelFactory',
            'Rally.data.wsapi.TreeStoreBuilder',
            'Rally.ui.dialog.CsvImportDialog',
            'Rally.ui.gridboard.GridBoard',
            'Rally.apps.iterationtrackingboard.IterationTrackingTreeGrid',
            'Rally.ui.cardboard.plugin.FixedHeader',
            'Rally.ui.cardboard.plugin.Print',
            'Rally.ui.gridboard.plugin.GridBoardActionsMenu',
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl',
            'Rally.ui.gridboard.plugin.GridBoardFilterInfo',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.ui.cardboard.plugin.ColumnPolicy',
            'Rally.ui.gridboard.plugin.GridBoardFilterInfo',
            'Rally.ui.gridboard.plugin.GridBoardFilterControl',
            'Rally.ui.gridboard.plugin.GridBoardToggleable',
            'Rally.ui.grid.plugin.TreeGridExpandedRowPersistence',
            'Rally.ui.grid.plugin.TreeGridChildPager',
            'Rally.ui.gridboard.plugin.GridBoardExpandAll',
            'Rally.ui.gridboard.plugin.GridBoardCustomView',
            'Rally.ui.filter.view.ModelFilter',
            'Rally.ui.filter.view.OwnerFilter',
            'Rally.ui.filter.view.OwnerPillFilter',
            'Rally.ui.filter.view.TagPillFilter',
            'Rally.app.Message',
            'Rally.apps.iterationtrackingboard.Column',
            'Rally.apps.iterationtrackingboard.StatsBanner',
            'Rally.apps.iterationtrackingboard.StatsBannerField',
            'Rally.clientmetrics.ClientMetricsRecordable',
            'Rally.apps.iterationtrackingboard.PrintDialog',
            'Rally.ui.grid.plugin.ColumnAutoSizer',
            'Rally.apps.common.RowSettingsField'
        ],

        mixins: [
            'Rally.app.CardFieldSelectable',
            'Rally.clientmetrics.ClientMetricsRecordable'
        ],
        componentCls: 'iterationtrackingboard',
        alias: 'widget.rallyiterationtrackingboard',

        settingsScope: 'project',
        userScopedSettings: true,
        scopeType: 'iteration',
        autoScroll: false,

        config: {
            defaultSettings: {
                showCardAge: true,
                showStatsBanner: true,
                cardAgeThreshold: 3
            }
        },

        modelNames: ['User Story', 'Defect', 'Defect Suite', 'Test Set'],

        onScopeChange: function() {
            if(!this.rendered) {
                this.on('afterrender', this.onScopeChange, this, {single: true});
                return;
            }

            var grid = this.down('rallytreegrid');
            if (grid) {
                // reset page count to 1.
                // must be called here to reset persisted page count value.
                grid.fireEvent('storecurrentpagereset');
            }

            if(this._shouldShowStatsBanner()){
                this._addStatsBanner();
            }

            this._buildGridStore().then({
                success: function(gridStore) {
                    var model = gridStore.model;
                    if(_.isFunction(model.getArtifactComponentModels)) {
                        this.modelNames = _.intersection(_.pluck(gridStore.model.getArtifactComponentModels(),'displayName'),this.modelNames);
                    } else {
                        this.modelNames = [model.displayName];
                    }
                    this._addGridBoard(gridStore);
                },
                scope: this
            });
        },

        getSettingsFields: function () {
            var fields = this.callParent(arguments);

            fields.push({
                type: 'cardage',
                config: {
                    margin: '0 0 0 80',
                    width: 300
                }
            });

            if (this._shouldShowSwimLanes()) {
                fields.push({
                    name: 'groupHorizontallyByField',
                    xtype: 'rowsettingsfield',
                    fieldLabel: 'Swimlanes',
                    margin: '10 0 0 0',
                    mapsToMultiplePreferenceKeys: ['showRows', 'rowsField'],
                    readyEvent: 'ready',
                    includeCustomFields: false,
                    explicitFields: [
                        {name: 'Blocked', value: 'Blocked'},
                        {name: 'Owner', value: 'Owner'},
                        {name: 'Sizing', value: 'PlanEstimate'},
                        {name: 'Expedite', value: 'Expedite'}
                    ]
                });
            }

            return fields;
        },

        getUserSettingsFields: function () {
            var fields = this.callParent(arguments);

            fields.push({
                xtype: 'rallystatsbannersettingsfield',
                fieldLabel: '',
                mapsToMultiplePreferenceKeys: ['showStatsBanner']
            });

            return fields;
        },

        _buildGridStore: function() {
            var context = this.getContext(),
                config = {
                    models: this.modelNames,
                    autoLoad: false,
                    remoteSort: true,
                    root: {expanded: true},
                    enableHierarchy: true,
                    pageSize: this.getGridPageSizes()[1],
                    childPageSizeEnabled: context.isFeatureEnabled('EXPAND_ALL_TREE_GRID_CHILDREN')
                };

            if(!context.isFeatureEnabled('USE_CUSTOM_FILTER_POPOVER_ON_ITERATION_TRACKING_APP')) {
                config.filters = [context.getTimeboxScope().getQueryFilter()];
            }

            return Ext.create('Rally.data.wsapi.TreeStoreBuilder').build(config);
        },

        _shouldShowSwimLanes: function() {
            return this.getContext().isFeatureEnabled('F5684_KANBAN_SWIM_LANES');
        },

        _shouldShowStatsBanner: function() {
            return this.getSetting('showStatsBanner');
        },

        _addStatsBanner: function() {
           this.remove('statsBanner');
           this.add({
                xtype: 'statsbanner',
                itemId: 'statsBanner',
                context: this.getContext(),
                margin: '0 0 5px 0',
                listeners: {
                    resize: this._resizeGridBoardToFillSpace,
                    scope: this
                }
            });
        },

        _addGridBoard: function (gridStore) {
            var context = this.getContext();

            this.remove('gridBoard');

            this.gridboard = this.add({
                itemId: 'gridBoard',
                xtype: 'rallygridboard',
                stateId: 'iterationtracking-gridboard',
                context: context,
                plugins: this._getGridBoardPlugins(),
                modelNames: this.modelNames,
                cardBoardConfig: this._getBoardConfig(),
                gridConfig: this._getGridConfig(gridStore),
                storeConfig: {
                    useShallowFetch: false,
                    filters: [context.getTimeboxScope().getQueryFilter()]
                },
                addNewPluginConfig: {
                    style: {
                        'float': 'left'
                    }
                },
                listeners: {
                    load: this._onLoad,
                    toggle: this._onToggle,
                    recordupdate: this._publishContentUpdatedNoDashboardLayout,
                    recordcreate: this._publishContentUpdatedNoDashboardLayout,
                    scope: this
                },
                height: Math.max(this.getAvailableGridBoardHeight(), 150)
            });
        },

        _getBoardConfig: function() {
            var config = {
                plugins: [
                    {ptype: 'rallycardboardprinting', pluginId: 'print'},
                    {ptype: 'rallyfixedheadercardboard'}
                ],
                columnConfig: {
                    xtype: 'iterationtrackingboardcolumn',
                    additionalFetchFields: ['PortfolioItem'],
                    plugins: [{
                        ptype: 'rallycolumnpolicy',
                        app: this
                    }]
                },
                cardConfig: {
                    showAge: this.getSetting('showCardAge') ? this.getSetting('cardAgeThreshold') : -1
                },
                listeners: {
                    filter: this._onBoardFilter,
                    filtercomplete: this._onBoardFilterComplete
                }
            };

            if (this._shouldShowSwimLanes() && this.getSetting('showRows') && this.getSetting('rowsField')) {
                Ext.merge(config, {
                    rowConfig: {
                        field: this.getSetting('rowsField'),
                        sortDirection: 'ASC'
                    }
                });
            }

            return config;
        },

        /**
         * @private
         */
        getAvailableGridBoardHeight: function() {
            var height = this.getHeight();
            if(this._shouldShowStatsBanner() && this.down('#statsBanner').rendered) {
                height -= this.down('#statsBanner').getHeight();
            }
            return height;
        },

        _getGridBoardPlugins: function() {
            var plugins = ['rallygridboardaddnew'];
            var context = this.getContext();

            if (context.isFeatureEnabled('EXPAND_ALL_TREE_GRID_CHILDREN') && !Ext.isIE) {
                plugins.push('rallygridboardexpandall');
            }

            if (context.isFeatureEnabled('BETA_TRACKING_EXPERIENCE')) {
                if (context.isFeatureEnabled('USE_CUSTOM_FILTER_POPOVER_ON_ITERATION_TRACKING_APP')) {
                    plugins.push({
                        ptype: 'rallygridboardcustomfiltercontrol',
                        filterChildren: this.getContext().isFeatureEnabled('S58650_ALLOW_WSAPI_TRAVERSAL_FILTER_FOR_MULTIPLE_TYPES'),
                        filterControlConfig: {
                            blackListFields: ['Iteration', 'PortfolioItem'],
                            context: context,
                            margin: '3 9 3 30',
                            modelNames: this.modelNames,
                            stateful: true,
                            stateId: context.getScopedStateId('iteration-tracking-custom-filter-button')
                        }
                    });
                } else {
                    plugins.push({
                        ptype: 'rallygridboardfiltercontrol',
                        filterControlConfig: {
                            cls: 'small gridboard-filter-control',
                            context: context,
                            items: [
                                this._createOwnerFilterItem(context),
                                this._createTagFilterItem(context),
                                this._createModelFilterItem(context)
                            ],
                            stateful: true,
                            stateId: context.getScopedStateId('iteration-tracking-filter-button')
                        }
                    });
                }
            }

            plugins.push('rallygridboardtoggleable');

            var actionsMenuItems = [
            {
                text: 'Import User Stories...',
                handler: this._importHandler({
                    type: 'userstory',
                    title: 'Import User Stories'
                })
            }, {
                text: 'Import Tasks...',
                handler: this._importHandler({
                    type: 'task',
                    title: 'Import Tasks'
                })
            }, {
                text: 'Export...',
                handler: this._exportHandler,
                scope: this
            }];

            actionsMenuItems.push({
                text: 'Print...',
                handler: this._printHandler,
                scope: this
            });

            plugins.push({
                ptype: 'rallygridboardactionsmenu',
                itemId: 'printExportMenuButton',
                menuItems: actionsMenuItems,
                buttonConfig: {
                    iconCls: 'icon-export',
                    toolTipConfig: {
                        html: 'Import/Export/Print',
                        anchor: 'top',
                        hideDelay: 0
                    }
                }
            });

            var alwaysSelectedValues = ['FormattedID', 'Name', 'Owner'];
            if (context.getWorkspace().WorkspaceConfiguration.DragDropRankingEnabled) {
                alwaysSelectedValues.push('DragAndDropRank');
            }

            if (!context.isFeatureEnabled('BETA_TRACKING_EXPERIENCE')) {
                plugins.push({
                    ptype: 'rallygridboardfilterinfo',
                    isGloballyScoped: Ext.isEmpty(this.getSetting('project')),
                    stateId: 'iteration-tracking-owner-filter-' + this.getAppId()
                });
            }

            plugins.push({
                ptype: 'rallygridboardfieldpicker',
                headerPosition: 'left',
                gridFieldBlackList: [
                    'ObjectID',
                    'Description',
                    'DisplayColor',
                    'Notes',
                    'Subscription',
                    'Workspace',
                    'Changesets',
                    'RevisionHistory',
                    'Children',
                    'Successors',
                    'Predecessors'
                ],
                boardFieldBlackList: [
                    'PredecessorsAndSuccessors'
                ],
                alwaysSelectedValues: alwaysSelectedValues,
                modelNames: this.modelNames,
                boardFieldDefaults: (this.getSetting('cardFields') && this.getSetting('cardFields').split(',')) ||
                    ['Parent', 'Tasks', 'Defects', 'Discussion', 'PlanEstimate', 'Iteration']
            });

            if (context.isFeatureEnabled('ITERATION_TRACKING_CUSTOM_VIEWS')) {
                plugins.push(this._getCustomViewConfig());
            }

            return plugins;
        },

        setHeight: Ext.Function.createBuffered(function() {
            this.superclass.setHeight.apply(this, arguments);
            this._resizeGridBoardToFillSpace();
        }, 100),

        _importHandler: function(options) {
            return _.bind(function() {
                Rally.data.WsapiModelFactory.getModel({
                    type: options.type,
                    success: function(model) {
                        Ext.widget({
                            xtype: 'rallycsvimportdialog',
                            model: model,
                            title: options.title,
                            params: {
                                iterationOid: this._getIterationOid()
                            }
                        });
                    },
                    scope: this
                });
            }, this);
        },

        _exportHandler: function() {
            var context = this.getContext();
            var params = {
                cpoid: context.getProject().ObjectID,
                projectScopeUp: context.getProjectScopeUp(),
                projectScopeDown: context.getProjectScopeDown(),
                iterationKey: this._getIterationOid()
            };

            window.location = Ext.String.format('{0}/sc/exportCsv.sp?{1}',
                Rally.environment.getServer().getContextUrl(),
                Ext.Object.toQueryString(params)
            );
        },

        _printHandler: function() {
            var gridBoard = this.queryById('gridBoard');
            var gridOrBoard = gridBoard.getGridOrBoard();
            var totalRows = gridOrBoard.store.totalCount;
            var timeboxScope = this.getContext().getTimeboxScope();

            Ext.create('Rally.apps.iterationtrackingboard.PrintDialog', {
                showWarning: totalRows > 200,
                timeboxScope: timeboxScope,
                grid: gridOrBoard
            });
        },

        _getIterationOid: function() {
            var iterationId = '-1';
            var timebox = this.getContext().getTimeboxScope();

            if (timebox && timebox.getRecord()) {
                iterationId = timebox.getRecord().getId();
            }
            return iterationId;
        },

        _resizeGridBoardToFillSpace: function() {
            if (this.gridboard) {
                this.gridboard.setHeight(this.getAvailableGridBoardHeight());
            }
        },

        _getCustomViewConfig: function() {
            var customViewConfig = {
                ptype: 'rallygridboardcustomview',
                stateId: 'iteration-tracking-board-app',

                defaultGridViews: [{
                    model: ['UserStory', 'Defect', 'DefectSuite', 'TestSet'],
                    name: 'Defect Status',
                    state: {
                        cmpState: {
                            expandAfterApply: true,
                            columns: [
                                'Name',
                                'State',
                                'Discussion',
                                'Priority',
                                'Severity',
                                'FoundIn',
                                'FixedIn',
                                'Owner'
                            ]
                        },
                        filterState: {
                            filter: {
                                defectstatusview: {
                                    isActiveFilter: false,
                                    itemId: 'defectstatusview',
                                    queryString: '((Defects.ObjectID != null) OR (Priority != null))'
                                }
                            }
                        }
                    }
                }, {
                    model: ['UserStory', 'Defect', 'TestSet', 'DefectSuite'],
                    name: 'Task Status',
                    state: {
                        cmpState: {
                            expandAfterApply: true,
                            columns: [
                                'Name',
                                'State',
                                'PlanEstimate',
                                'TaskEstimate',
                                'ToDo',
                                'Discussions',
                                'Owner'
                            ]
                        },
                        filterState: {
                            filter: {
                                taskstatusview: {
                                    isActiveFilter: false,
                                    itemId: 'taskstatusview',
                                    queryString: '(Tasks.ObjectID != null)'
                                }
                            }
                        }
                    }
                }, {
                    model: ['UserStory', 'Defect', 'TestSet'],
                    name: 'Test Status',
                    state: {
                        cmpState: {
                            expandAfterApply: true,
                            columns: [
                                'Name',
                                'State',
                                'Discussions',
                                'LastVerdict',
                                'LastBuild',
                                'LastRun',
                                'ActiveDefects',
                                'Priority',
                                'Owner'
                            ]
                        },
                        filterState: {
                            filter: {
                                teststatusview: {
                                    isActiveFilter: false,
                                    itemId: 'teststatusview',
                                    queryString: '(TestCases.ObjectID != null)'
                                }
                            }
                        }
                    }
                }]
            };

            customViewConfig.defaultBoardViews = _.cloneDeep(customViewConfig.defaultGridViews);
            _.each(customViewConfig.defaultBoardViews, function(view) {
                delete view.state.cmpState;
            });

            return customViewConfig;
        },

        _createOwnerFilterItem: function (context) {
            var isPillPickerEnabled = context.isFeatureEnabled('BETA_TRACKING_EXPERIENCE'),
                projectRef = context.getProjectRef();

            if (isPillPickerEnabled) {
                return {
                    xtype: 'rallyownerpillfilter',
                    margin: '-15 0 5 0',
                    filterChildren: this.getContext().isFeatureEnabled('S58650_ALLOW_WSAPI_TRAVERSAL_FILTER_FOR_MULTIPLE_TYPES'),
                    project: projectRef,
                    showPills: false,
                    showClear: true
                };
            } else {
                return {
                    xtype: 'rallyownerfilter',
                    margin: '5 0 5 0',
                    filterChildren: this.getContext().isFeatureEnabled('S58650_ALLOW_WSAPI_TRAVERSAL_FILTER_FOR_MULTIPLE_TYPES'),
                    project: projectRef
                };
            }

        },

        _createTagFilterItem: function (context) {
            var filterUiImprovementsToggleEnabled = context.isFeatureEnabled('BETA_TRACKING_EXPERIENCE');
            return {
                xtype: 'rallytagpillfilter',
                margin: filterUiImprovementsToggleEnabled ? '-15 0 5 0' : '5 0 5 0',
                showPills: filterUiImprovementsToggleEnabled,
                showClear: filterUiImprovementsToggleEnabled,
                remoteFilter: filterUiImprovementsToggleEnabled
            };
        },

        _createModelFilterItem: function (context) {
            return {
                xtype: 'rallymodelfilter',
                models: this.modelNames,
                context: context
            };
        },

        _getGridConfig: function (gridStore) {
            var context = this.getContext(),
                stateString = 'iteration-tracking-treegrid',
                stateId = context.getScopedStateId(stateString);

            var gridConfig = {
                xtype: 'rallyiterationtrackingtreegrid',
                store: gridStore,
                columnCfgs: this._getGridColumns(),
                summaryColumns: this._getSummaryColumnConfig(),
                enableBulkEdit: context.isFeatureEnabled('BETA_TRACKING_EXPERIENCE'),
                plugins: ['rallycolumnautosizerplugin', 'rallytreegridchildpager'],
                stateId: stateId,
                stateful: true
            };

            if (context.isFeatureEnabled('EXPAND_ALL_TREE_GRID_CHILDREN')) {
                gridConfig.plugins.push({
                    ptype: 'rallytreegridexpandedrowpersistence',
                    enableExpandLoadingMask: !context.isFeatureEnabled('EXPAND_ALL_LOADING_MASK_DISABLE')
                });
            }

            if (context.isFeatureEnabled('S67643_LIMIT_TREEGRID_PAGE_SIZE')) {
                gridConfig.pagingToolbarCfg = {
                    pageSizes: this.getGridPageSizes()
                };
            }

            return gridConfig;
        },

        _getSummaryColumnConfig: function () {
            var taskUnitName = this.getContext().getWorkspace().WorkspaceConfiguration.TaskUnitName,
                planEstimateUnitName = this.getContext().getWorkspace().WorkspaceConfiguration.IterationEstimateUnitName;

            return [
                {
                    field: 'PlanEstimate',
                    type: 'sum',
                    units: planEstimateUnitName
                },
                {
                    field: 'TaskEstimateTotal',
                    type: 'sum',
                    units: taskUnitName
                },
                {
                    field: 'TaskRemainingTotal',
                    type: 'sum',
                    units: taskUnitName
                }
            ];
        },

        _getGridColumns: function (columns) {
            return columns ? _.without(columns, 'FormattedID') : defaultGridColumns;
        },

        _onLoad: function () {
            this._publishContentUpdated();

            var additionalMetricData = {};

            if  (this.gridboard.getToggleState() === 'board') {
                additionalMetricData = {
                    miscData: {
                        swimLanes: this.getSetting('showRows'),
                        swimLaneField: this.getSetting('rowsField')
                    }
                };
            }

            this.recordComponentReady(additionalMetricData);

            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this);
            }
        },

        _onBoardFilter: function () {
            this.setLoading(true);
        },

        _onBoardFilterComplete: function () {
            this.setLoading(false);
        },

        _hidePrintButton: function(hide, gridboard) {
            var button, menuItem;

            if (gridboard) {
                button = _.find(gridboard.plugins, {itemId: 'printExportMenuButton'});

                if (button) {
                    menuItem = _.find(button.menuItems, {text: 'Print...'});

                    if (menuItem) {
                        menuItem.hidden = hide;
                    }
                }
            }
        },

        _onToggle: function (toggleState, gridOrBoard, gridboard) {
            var appEl = this.getEl();

            if (toggleState === 'board') {
                appEl.replaceCls('grid-toggled', 'board-toggled');
                this._hidePrintButton(true, gridboard);
            } else {
                appEl.replaceCls('board-toggled', 'grid-toggled');
                this._hidePrintButton(false, gridboard);
            }
            this._publishContentUpdated();
        },

        _publishContentUpdated: function () {
            this.fireEvent('contentupdated');
        },

        _publishContentUpdatedNoDashboardLayout: function () {
            this.fireEvent('contentupdated', {dashboardLayout: false});
        },

        getGridPageSizes: function() {
            return Ext.isIE ? [10, 25, 50] : [10, 25, 50, 100];
        }
    });
})();

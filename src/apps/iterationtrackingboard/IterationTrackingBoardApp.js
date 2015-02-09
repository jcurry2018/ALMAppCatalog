(function () {
    var Ext = window.Ext4 || window.Ext;

    var defaultGridColumns = ['Name', 'ScheduleState', 'Blocked', 'PlanEstimate', 'Tasks', 'TaskEstimateTotal', 'TaskRemainingTotal', 'Owner', 'Defects', 'Discussion'];

    /**
     * Iteration Tracking Board App
     * The Iteration Tracking Board can be used to visualize and manage your User Stories and Defects within an Iteration.
     */
    Ext.define('Rally.apps.iterationtrackingboard.IterationTrackingBoardApp', {
        extend: 'Rally.app.TimeboxScopedApp',
        requires: [
            'Rally.data.Ranker',
            'Rally.data.wsapi.ModelFactory',
            'Rally.data.wsapi.TreeStoreBuilder',
            'Rally.ui.dialog.CsvImportDialog',
            'Rally.ui.gridboard.GridBoard',
            'Rally.ui.cardboard.plugin.FixedHeader',
            'Rally.ui.cardboard.plugin.Print',
            'Rally.ui.gridboard.plugin.GridBoardActionsMenu',
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.ui.cardboard.plugin.ColumnPolicy',
            'Rally.ui.gridboard.plugin.GridBoardToggleable',
            'Rally.ui.grid.plugin.TreeGridExpandedRowPersistence',
            'Rally.ui.grid.plugin.TreeGridChildPager',
            'Rally.ui.gridboard.plugin.GridBoardCustomView',
            'Rally.ui.filter.view.ModelFilter',
            'Rally.ui.filter.view.OwnerFilter',
            'Rally.ui.filter.view.OwnerPillFilter',
            'Rally.ui.filter.view.TagPillFilter',
            'Rally.app.Message',
            'Rally.apps.iterationtrackingboard.StatsBanner',
            'Rally.apps.iterationtrackingboard.StatsBannerField',
            'Rally.clientmetrics.ClientMetricsRecordable',
            'Rally.apps.common.RowSettingsField'
        ],

        mixins: [
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
            },
            includeStatsBanner: true
        },

        modelNames: ['User Story', 'Defect', 'Defect Suite', 'Test Set'],

        constructor: function(config) {
            _.defaults(config, { layout: 'anchor'});

            this.callParent(arguments);
        },

        onScopeChange: function() {
            if(!this.rendered) {
                this.on('afterrender', this.onScopeChange, this, {single: true});
                return;
            }

            var me = this;

            this.suspendLayouts();

            var grid = this.down('rallytreegrid');
            if (grid) {
                // reset page count to 1.
                // must be called here to reset persisted page count value.
                grid.fireEvent('storecurrentpagereset');
            }

            if (this._shouldShowStatsBanner()){
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
            }).always(function() {
                me.resumeLayouts(true);
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

            fields.push({
                name: 'groupHorizontallyByField',
                xtype: 'rowsettingsfield',
                fieldLabel: 'Swimlanes',
                margin: '10 0 0 0',
                mapsToMultiplePreferenceKeys: ['showRows', 'rowsField'],
                readyEvent: 'ready',
                isAllowedFieldFn: function() { return false; },
                explicitFields: [
                    {name: 'Blocked', value: 'Blocked'},
                    {name: 'Owner', value: 'Owner'},
                    {name: 'Sizing', value: 'PlanEstimate'},
                    {name: 'Expedite', value: 'Expedite'}
                ]
            });

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
                    context: context.getDataContext(),
                    models: this.modelNames,
                    autoLoad: false,
                    remoteSort: true,
                    root: {expanded: true},
                    enableHierarchy: true,
                    pageSize: this.getGridPageSizes()[1],
                    childPageSizeEnabled: true,
                    fetch: ['PlanEstimate', 'Release', 'Iteration']
                };

            return Ext.create('Rally.data.wsapi.TreeStoreBuilder').build(config);
        },

        _shouldShowStatsBanner: function() {
            return this.includeStatsBanner && this.getSetting('showStatsBanner');
        },

        _addStatsBanner: function() {
           this.remove('statsBanner');
           this.add({
                xtype: 'statsbanner',
                itemId: 'statsBanner',
                context: this.getContext(),
                margin: '0 0 5px 0',
                shouldOptimizeLayouts: this.config.optimizeFrontEndPerformanceIterationStatus,
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
                layout: 'anchor',
                storeConfig: {
                    useShallowFetch: false,
                    filters: this._getGridboardFilters(gridStore.model)
                },
                listeners: {
                    load: this._onLoad,
                    toggle: this._onToggle,
                    recordupdate: this._publishContentUpdatedNoDashboardLayout,
                    recordcreate: this._publishContentUpdatedNoDashboardLayout,
                    scope: this
                },
                height: Math.max(this._getAvailableGridBoardHeight(), 150)
            });
        },

        _getGridboardFilters: function(model) {
            var timeboxScope = this.getContext().getTimeboxScope(),
                timeboxFilter = timeboxScope.getQueryFilter(),
                filters = [timeboxFilter];

            if (!timeboxScope.getRecord() && this.getContext().getSubscription().StoryHierarchyEnabled) {
                filters.push(this._createLeafStoriesOnlyFilter(model));
                filters.push(this._createUnassociatedDefectsOnlyFilter(model));
            }
            return filters;
        },

        _createLeafStoriesOnlyFilter: function(model) {
            var typeDefOid = model.getArtifactComponentModel('HierarchicalRequirement').typeDefOid;

            var userStoryFilter = Ext.create('Rally.data.wsapi.Filter', {
                property: 'TypeDefOid',
                value: typeDefOid
            });

            var noChildrenFilter = Ext.create('Rally.data.wsapi.Filter', {
                property: 'DirectChildrenCount',
                value: 0
            });

            var notUserStoryFilter = Ext.create('Rally.data.wsapi.Filter', {
                property: 'TypeDefOid',
                value: typeDefOid,
                operator: '!='
            });

            return userStoryFilter.and(noChildrenFilter).or(notUserStoryFilter);
        },

        _createUnassociatedDefectsOnlyFilter: function(model) {
            var typeDefOid = model.getArtifactComponentModel('Defect').typeDefOid,
                isADefect = Ext.create('Rally.data.wsapi.Filter', {
                    property: 'TypeDefOid',
                    value: typeDefOid
                }),
                parentRequirementIsScheduled = Ext.create('Rally.data.wsapi.Filter', {
                    property: 'Requirement.Iteration',
                    operator: '!=',
                    value: null
                }),
                hasNoParentRequirement = Ext.create('Rally.data.wsapi.Filter', {
                    property: 'Requirement',
                    operator: '=',
                    value: null
                }),
                isNotADefect = Ext.create('Rally.data.wsapi.Filter', {
                    property: 'TypeDefOid',
                    value: typeDefOid,
                    operator: '!='
                });

            return isADefect.and(parentRequirementIsScheduled.or(hasNoParentRequirement)).or(isNotADefect);
        },

        _getBoardConfig: function() {
            var config = {
                plugins: [
                    {ptype: 'rallycardboardprinting', pluginId: 'print'},
                    {ptype: 'rallyfixedheadercardboard'}
                ],
                columnConfig: {
                    additionalFetchFields: ['PortfolioItem'],
                    plugins: [{
                        ptype: 'rallycolumnpolicy',
                        app: this
                    }],
                    requiresModelSpecificFilters: false
                },
                cardConfig: {
                    showAge: this.getSetting('showCardAge') ? this.getSetting('cardAgeThreshold') : -1
                },
                listeners: {
                    filter: this._onBoardFilter,
                    filtercomplete: this._onBoardFilterComplete
                }
            };

            if (this.getSetting('showRows') && this.getSetting('rowsField')) {
                Ext.merge(config, {
                    rowConfig: {
                        field: this.getSetting('rowsField'),
                        sortDirection: 'ASC'
                    }
                });
            }

            return config;
        },

        _getAvailableGridBoardHeight: function() {
            var height = this.getHeight();
            if (this._shouldShowStatsBanner() && this.down('#statsBanner').rendered) {
                height -= this.down('#statsBanner').getHeight();
            }
            if (this.getHeader()) {
                height -= this.getHeader().getHeight();
            }
            return height;
        },

        _getGridBoardPlugins: function() {
            var context = this.getContext();
            var plugins = [{
                ptype: 'rallygridboardaddnew',
                addNewControlConfig: {
                    stateful: true,
                    stateId: context.getScopedStateId('iteration-tracking-add-new')
                }
            }];

            plugins.push({
                ptype: 'rallygridboardcustomfiltercontrol',
                filterChildren: true,
                filterControlConfig: {
                    blackListFields: ['Iteration', 'PortfolioItem'],
                    whiteListFields: ['Milestones'],
                    modelNames: this.modelNames,
                    stateful: true,
                    stateId: context.getScopedStateId('iteration-tracking-custom-filter-button')
                },
                showOwnerFilter: true,
                ownerFilterControlConfig: {
                    stateful: true,
                    stateId: context.getScopedStateId('iteration-tracking-owner-filter')
                }
            });

            plugins.push('rallygridboardtoggleable');

            var actionsMenuItems = [
            {
                text: 'Import User Stories...',
                handler: this._importHandler({
                    type: 'HierarchicalRequirement',
                    title: 'Import User Stories'
                })
            }, {
                text: 'Import Tasks...',
                handler: this._importHandler({
                    type: 'Task',
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

            plugins.push({
                ptype: 'rallygridboardfieldpicker',
                headerPosition: 'left',
                gridFieldBlackList: [
                    'Estimate',
                    'ToDo'
                ],
                boardFieldBlackList: [
                    'Successors',
                    'Predecessors'
                ],
                modelNames: this.modelNames,
                boardFieldDefaults: (this.getSetting('cardFields') && this.getSetting('cardFields').split(',')) ||
                    ['Parent', 'Tasks', 'Defects', 'Discussion', 'PlanEstimate', 'Iteration']
            });

            if (context.isFeatureEnabled('ITERATION_TRACKING_CUSTOM_VIEWS')) {
                plugins.push(this._getCustomViewConfig());
            }

            return plugins;
        },

        setSize: function() {
            this.callParent(arguments);
            this._resizeGridBoardToFillSpace();
        },

        _importHandler: function(options) {
            return _.bind(function() {
                Ext.widget({
                    xtype: 'rallycsvimportdialog',
                    type: options.type,
                    title: options.title,
                    params: {
                        iterationOid: this._getIterationOid()
                    }
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
            var timeboxScope = this.getContext().getTimeboxScope();

            Ext.create('Rally.ui.grid.TreeGridPrintDialog', {
                grid: this.gridboard.getGridOrBoard(),
                treeGridPrinterConfig: {
                    largeHeaderText: 'Iteration Summary',
                    smallHeaderText: timeboxScope.getRecord() ? timeboxScope.getRecord().get('Name') : 'Unscheduled'
                }
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
                this.gridboard.setHeight(this._getAvailableGridBoardHeight());
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

        _getGridConfig: function (gridStore) {
            var context = this.getContext(),
                stateString = 'iteration-tracking-treegrid',
                stateId = context.getScopedStateId(stateString),
                useFixedHeightRows = Ext.isIE && context.isFeatureEnabled('S78815_ITERATON_TREE_GRID_APP_FIXED_ROW_HEIGHT');

            var gridConfig = {
                bufferedRenderer: true,
                columnCfgs: this._getGridColumns(),
                enableBulkEdit: true,
                enableInlineAdd: true,
                enableSummaryRow: true,
                expandAllInColumnHeaderEnabled: true,
                inlineAddConfig: {
                    enableAddPlusNewChildStories: false
                },
                noDataHelpLink: {
                    url: "https://help.rallydev.com/tracking-iterations#filter",
                    title: "Filter Help Page"
                },
                pagingToolbarCfg: {
                    pageSizes: this.getGridPageSizes(),
                    comboboxConfig: {
                        defaultSelectionPosition: 'last'
                    }
                },
                plugins: [],
                stateful: true,
                stateId: stateId,
                store: gridStore,
                variableRowHeight: !useFixedHeightRows
            };

            gridConfig.plugins.push({
                ptype: 'rallytreegridexpandedrowpersistence'
            });

            return gridConfig;
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

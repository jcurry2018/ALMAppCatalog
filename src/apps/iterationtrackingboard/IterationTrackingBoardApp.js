(function() {
    var Ext = window.Ext4 || window.Ext;

    /**
     * Iteration Tracking Board App
     * The Iteration Tracking Board can be used to visualize and manage your User Stories and Defects within an Iteration.
     */
    Ext.define('Rally.apps.iterationtrackingboard.IterationTrackingBoardApp', {
        extend: 'Rally.app.TimeboxScopedApp',
        requires: [
            'Rally.data.ModelFactory',
            'Rally.data.Ranker',
            'Rally.ui.gridboard.GridBoard',
            'Rally.ui.grid.TreeGrid',
            'Rally.ui.cardboard.plugin.FixedHeader',
            'Rally.ui.cardboard.plugin.Print',
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.gridboard.plugin.GridBoardOwnerFilter',
            'Rally.ui.gridboard.plugin.GridBoardFilterInfo',
            'Rally.ui.gridboard.plugin.GridBoardArtifactTypeChooser',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.ui.cardboard.plugin.ColumnPolicy',
            'Rally.ui.gridboard.plugin.GridBoardFilterInfo',
            'Rally.ui.gridboard.plugin.GridBoardFilterControl',
            'Rally.ui.gridboard.plugin.GridBoardToggleable',
            'Rally.ui.filter.view.ModelFilter',
            'Rally.ui.filter.view.OwnerFilter',
            'Rally.ui.filter.view.OwnerPillFilter',
            'Rally.ui.filter.view.TagPillFilter',
            'Rally.app.Message',
            'Rally.apps.iterationtrackingboard.IsLeafHelper',
            'Rally.clientmetrics.ClientMetricsRecordable'
        ],
        mixins: [
            'Rally.app.CardFieldSelectable',
            'Rally.clientmetrics.ClientMetricsRecordable'
        ],
        componentCls: 'iterationtrackingboard',
        alias: 'widget.rallyiterationtrackingboard',

        settingsScope: 'project',
        scopeType: 'iteration',

        config: {
            defaultSettings: {
                showCardAge: true,
                cardAgeThreshold: 3,
                cardFields: 'Parent,Tasks,Defects,Discussion,PlanEstimate'
            }
        },

        onScopeChange: function(scope) {
            this._loadModels();
        },

        getSettingsFields: function () {
            var fields = this.callParent(arguments);

            if (!this.isShowingBlankSlate()) {
                this.appendCardFieldPickerSetting(fields);
                if (this.showGridSettings) {
                    fields.push({xtype: 'component', settingsType: 'grid', html: 'There are currently no grid settings', cls: 'settings-no-grid'});
                }
            }

            fields.push({
                type: 'cardage',
                settingsType: 'board',
                config: {
                    margin: '0 0 0 80',
                    width: 300
                }
            });

            return fields;
        },

        launch: function() {
            this.showGridSettings = this.getContext().isFeatureEnabled('ITERATION_TRACKING_BOARD_GRID_TOGGLE');
            this.callParent(arguments);
        },

        _addGridBoard: function(compositeModel, treeGridModel) {
            var plugins = ['rallygridboardaddnew'],
                context = this.getContext();

            if (context.isFeatureEnabled('F4359_FILTER')) {
                plugins.push({
                    ptype: 'rallygridboardfiltercontrol',
                    filterControlConfig: {
                        cls: 'small gridboard-filter-control',
                        stateful: true,
                        stateId: context.getScopedStateId('iteration-tracking-filter-button'),
                        items: [
                            this._createOwnerFilterItem(context),
                            this._createTagFilterItem(context),
                            {
                                xtype: 'rallymodelfilter',
                                models: compositeModel.getArtifactComponentModels()
                            }
                        ]
                    }
                });
            } else {
                plugins.push('rallygridboardownerfilter');
            }

            if (context.isFeatureEnabled('ITERATION_TRACKING_BOARD_GRID_TOGGLE')) {
                plugins.push('rallygridboardtoggleable');
            }

            var alwaysSelectedValues = ['FormattedID', 'Name', 'Owner'];
            if (this.getContext().getWorkspace().WorkspaceConfiguration.DragDropRankingEnabled) {
                alwaysSelectedValues.push('DragAndDropRank');
            }

            if (!context.isFeatureEnabled('F4359_FILTER')) {
                plugins = plugins.concat([{
                        ptype: 'rallygridboardfilterinfo',
                        isGloballyScoped: Ext.isEmpty(this.getSetting('project')) ? true : false,
                        stateId: 'iteration-tracking-owner-filter-' + this.getAppId()
                }]);
            }

            plugins = plugins.concat([
                {
                    ptype: 'rallygridboardfieldpicker',
                    gridFieldBlackList: ['DisplayColor'],
                    alwaysSelectedValues: alwaysSelectedValues
                }
            ]);

            if (context.isFeatureEnabled('SHOW_ARTIFACT_CHOOSER_ON_ITERATION_BOARDS') && !context.isFeatureEnabled('F4359_FILTER')) {
                plugins.push({
                    ptype: 'rallygridboardartifacttypechooser',
                    artifactTypePreferenceKey: 'artifact-types',
                    showAgreements: true
                });
            }
            this.plugins = plugins;
            this._addGrid(this._getGridConfig(treeGridModel));
        },

        _addGrid: function(gridConfig){
            var context = this.getContext();

            this.remove('gridBoard');

            this.gridboard = this.add({
                itemId: 'gridBoard',
                xtype: 'rallygridboard',
                stateId: 'iterationtracking-gridboard',
                context: context,
                plugins: this.plugins,
                modelNames: this.modelNames,
                allModelNames: context.isFeatureEnabled('F2903_USE_ITERATION_TREE_GRID') ? this.allModelNames : null,
                cardBoardConfig: {
                    serverSideFiltering: context.isFeatureEnabled('F4359_FILTER'),
                    plugins: [
                        {ptype: 'rallycardboardprinting', pluginId: 'print'},
                        {ptype: 'rallyfixedheadercardboard'}
                    ],
                    columnConfig: {
                        additionalFetchFields: ['PortfolioItem'],
                        plugins: [{
                            ptype: 'rallycolumnpolicy',
                            app: this
                        }]
                    },
                    cardConfig: {
                        fields: this.getCardFieldNames(),
                        showAge: this.getSetting('showCardAge') ? this.getSetting('cardAgeThreshold') : -1,
                        showBlockedReason: true
                    },
                    listeners: {
                        filter: this._onBoardFilter,
                        filtercomplete: this._onBoardFilterComplete
                    }
                },
                gridConfig: gridConfig,
                addNewPluginConfig: {
                    style: {
                        'float': 'left'
                    }
                },
                listeners: {
                    load: this._onLoad,
                    toggle: this._publishContentUpdated,
                    recordupdate: this._publishContentUpdatedNoDashboardLayout,
                    recordcreate: this._publishContentUpdatedNoDashboardLayout,
                    scope: this
                }
            });
        },

        _createOwnerFilterItem: function(context) {
            var isPillPickerEnabled = context.isFeatureEnabled('S59980_S59981_S60525_FILTER_UI_IMPROVEMENTS'),
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

        _createTagFilterItem: function(context) {
            var filterUiImprovementsToggleEnabled = context.isFeatureEnabled('S59980_S59981_S60525_FILTER_UI_IMPROVEMENTS');
            return {
                xtype: 'rallytagpillfilter',
                margin: filterUiImprovementsToggleEnabled ? '-15 0 5 0' : '5 0 5 0',
                showPills: filterUiImprovementsToggleEnabled,
                showClear: filterUiImprovementsToggleEnabled,
                remoteFilter: filterUiImprovementsToggleEnabled
            };
        },

        _getGridConfig: function(treeGridModel, columns) {
            var context = this.getContext(),
                stateString = context.isFeatureEnabled('F2903_USE_ITERATION_TREE_GRID') ? 'iteration-tracking-treegrid' : 'iteration-tracking-grid',
                stateId = context.getScopedStateId(stateString),
                header = this.items.getAt(0),
                treeGridHeight =  this.container.getSize().height;

            if (header){
                treeGridHeight -= header.getHeight();
            }

            var gridConfig = {
                storeConfig: {
                    autoLoad: context.isFeatureEnabled('F4359_FILTER') ? false : true
                },
                columnCfgs: this._getGridColumns(),
                enableBulkEdit: context.isFeatureEnabled('EXT4_GRID_BULK_EDIT'),
                stateId: stateId,
                stateful: true,
                height: treeGridHeight
            };

            if (context.isFeatureEnabled('F2903_USE_ITERATION_TREE_GRID')) {
                var parentTypes = ['HierarchicalRequirement', 'Defect', 'DefectSuite'];
                if(this.getContext().getSubscription().isUnlimitedEdition()) {
                    parentTypes.push('TestSet');
                }
                Ext.apply(gridConfig, {
                    xtype: 'rallytreegrid',
                    model: treeGridModel,
                    parentFieldNames: {
                        defect: ['Requirement', 'DefectSuite'],
                        task: ['WorkProduct'],
                        testcase: ['WorkProduct']
                    },
                    storeConfig: {
                        parentTypes: parentTypes,
                        childTypes: ['Defect', 'Task', 'TestCase'],
                        filters: [this.context.getTimeboxScope().getQueryFilter()],
                        sorters: [{
                            property: Rally.data.Ranker.getRankField(treeGridModel),
                            direction: 'ASC'
                        },{
                            property: 'TaskIndex',
                            direction: 'ASC'
                        }],
                        fetch: ['FormattedID', 'Tasks', 'Defects', 'TestCases']
                    },
                    treeColumnRenderer: function(value, metaData, record, rowIdx, colIdx, store, view) {
                        store = store.treeStore || store;
                        return Rally.ui.renderer.RendererFactory.getRenderTemplate(store.model.getField('FormattedID')).apply(record.data);
                    },
                    columnCfgs: columns ? this._getGridColumns(columns) : null,
                    defaultColumnCfgs: this._getGridColumns(),
                    pageResetMessages: [Rally.app.Message.timeboxScopeChange],
                    isLeaf: Rally.apps.iterationtrackingboard.IsLeafHelper.isLeaf,
                    getIcon: function(record) {
                        return '';
                    },
                    enableColumnFiltering: this.getContext().isFeatureEnabled('TREE_GRID_COLUMN_FILTERING'),
                    disableColumnMenus: !this.getContext().isFeatureEnabled('TREE_GRID_COLUMN_FILTERING'),
                    showSummary: this.getContext().isFeatureEnabled('F4757_TREE_GRID_CHANGES'),
                    enableRanking: this.getContext().getWorkspace().WorkspaceConfiguration.DragDropRankingEnabled
                });
            }
            return gridConfig;
        },

        _getGridColumns: function(columns) {
            var context = this.getContext(),
                result = ['FormattedID', 'Name', 'ScheduleState', 'Blocked', 'PlanEstimate', 'TaskStatus', 'TaskEstimateTotal', 'TaskRemainingTotal', 'Owner', 'DefectStatus', 'Discussion'];

            if (context.isFeatureEnabled('F2903_USE_ITERATION_TREE_GRID')) {
                if (columns) {
                    result = columns;
                }
                _.pull(result, 'FormattedID');
            }

            return result;
        },

        _loadModels: function() {
            var topLevelTypes = ['User Story', 'Defect', 'Defect Suite'],
                allTypes = topLevelTypes.concat(['Task', 'Test Case']);
            if(this.getContext().getSubscription().isUnlimitedEdition()) {
                topLevelTypes.push('Test Set');
                allTypes.push('Test Set');
            }
            Rally.data.ModelFactory.getModels({
                types: allTypes,
                context: this.getContext().getDataContext(),
                success: function(models) {
                    var topLevelModels = _.filter(models, function(model, key) {
                            return _.contains(topLevelTypes, key);
                        }),
                        compositeModel = Rally.domain.WsapiModelBuilder.buildCompositeArtifact(topLevelModels, this.getContext()),
                        treeGridModel;
                    this.modelNames = topLevelTypes;
                    this.allModelNames = allTypes;
                    if (this.getContext().isFeatureEnabled('F2903_USE_ITERATION_TREE_GRID')) {
                        treeGridModel = Rally.domain.WsapiModelBuilder.buildCompositeArtifact(_.values(models), this.getContext());
                    }
                    this._addGridBoard(compositeModel, treeGridModel);
                },
                scope: this
            });
        },

        _onLoad: function() {
            this._publishContentUpdated();
            this.recordComponentReady();
        },

        _onBoardFilter: function() {
            this.setLoading(true);
        },

        _onBoardFilterComplete: function() {
            this.setLoading(false);
        },

        _publishContentUpdated: function() {
            this.fireEvent('contentupdated');
        },

        _publishContentUpdatedNoDashboardLayout: function() {
            this.fireEvent('contentupdated', {dashboardLayout: false});
        }
    });
})();

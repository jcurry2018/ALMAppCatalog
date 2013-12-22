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
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.gridboard.plugin.GridBoardOwnerFilter',
            'Rally.ui.gridboard.plugin.GridBoardFilterInfo',
            'Rally.ui.gridboard.plugin.GridBoardArtifactTypeChooser',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.ui.cardboard.plugin.ColumnPolicy',
            'Rally.ui.gridboard.plugin.GridBoardFilterInfo',
            'Rally.ui.gridboard.plugin.GridBoardFilterControl',
            'Rally.ui.filter.view.ModelFilter',
            'Rally.ui.filter.view.OwnerFilter',
            'Rally.ui.filter.view.TagFilter',
            'Rally.app.Message'
        ],
        mixins: ['Rally.app.CardFieldSelectable'],
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
            this.remove('gridBoard');
            this._loadModels();
        },

        getSettingsFields: function () {
            var fields = this.callParent(arguments);

            if (!this.isShowingBlankSlate()) {
                this.appendCardFieldPickerSetting(fields);
                if (this.showGridSettings) {
                    fields.push({settingsType: 'grid', html: 'no grid settings'});
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
                            {
                                xtype: 'rallyownerfilter',
                                margin: '0 5',
                                project: this.getContext().getProjectRef()
                            },
                            {
                                xtype: 'rallytagfilter',
                                margin: '0 5'
                            },
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

            plugins = plugins.concat([{
                    ptype: 'rallygridboardfilterinfo',
                    isGloballyScoped: Ext.isEmpty(this.getSetting('project')) ? true : false,
                    stateId: 'iteration-tracking-owner-filter-' + this.getAppId()
                },
                'rallygridboardfieldpicker'
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

            this.gridboard = this.add({
                itemId: 'gridBoard',
                xtype: 'rallygridboard',
                stateId: 'iterationtracking-gridboard',
                context: context,
                enableToggle: context.isFeatureEnabled('ITERATION_TRACKING_BOARD_GRID_TOGGLE'),
                plugins: this.plugins,
                modelNames: this.modelNames,
                allModelNames: context.isFeatureEnabled('F2903_USE_ITERATION_TREE_GRID') ? this.allModelNames : null,
                cardBoardConfig: {
                    serverSideFiltering: context.isFeatureEnabled('F4359_FILTER'),
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

        _getGridConfig: function(treeGridModel, columns) {
            var context = this.getContext(),
                stateString = context.isFeatureEnabled('F2903_USE_ITERATION_TREE_GRID') ? 'iteration-tracking-treegrid' : 'iteration-tracking-grid',
                stateId = context.getScopedStateId(stateString);

            var gridConfig = {
                storeConfig: {
                    autoLoad: context.isFeatureEnabled('F4359_FILTER') ? false : true
                },
                columnCfgs: this._getGridColumns(),
                enableBulkEdit: context.isFeatureEnabled('EXT4_GRID_BULK_EDIT'),
                stateId: stateId,
                stateful: context.isFeatureEnabled('ITERATION_TRACKING_PERSISTENT_PREFERENCES')
            };

            if (context.isFeatureEnabled('F2903_USE_ITERATION_TREE_GRID')) {
                Ext.apply(gridConfig, {
                    xtype: 'rallytreegrid',
                    model: treeGridModel,
                    storeConfig: {
                        nodeParam: 'Parent',
                        parentFieldNames: ['Requirement', 'WorkProduct', 'DefectSuite'],
                        parentTypes: ['HierarchicalRequirement', 'Defect', 'DefectSuite', 'TestSet'],
                        childTypes: ['Defect', 'Task', 'TestCase'],
                        rootNodeFilters: this.context.getTimeboxScope().getQueryFilter(),
                        sorters: {
                            property: Rally.data.Ranker.getRankField(treeGridModel),
                            direction: 'ASC'
                        },
                        fetch: ['FormattedID', 'Tasks', 'Defects', 'TestCases']
                    },
                    treeColumnRenderer: function(value, metaData, record, rowIdx, colIdx, store, view) {
                        return Rally.ui.renderer.RendererFactory.getRenderTemplate(store.model.getField('FormattedID')).apply(record.data);
                    },
                    rootVisible: false,
                    columnCfgs: columns ? this._getGridColumns(columns) : null,
                    defaultColumnCfgs: this._getGridColumns(),
                    pageResetMessages: [Rally.app.Message.timeboxScopeChange],
                    isLeaf: function(record) {
                        return  (!record.raw.Tasks || record.raw.Tasks.Count === 0) &&
                                (!record.raw.Defects || record.raw.Defects.Count === 0) &&
                                (record.raw._type === 'TestSet' || !record.raw.TestCases || record.raw.TestCases.Count === 0); //remove the type check once TestCases under TestSets can be queried through the artifact endpoint
                    },
                    getIcon: function(record) {
                        return '';
                    }
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
            var topLevelTypes = ['User Story', 'Defect', 'Defect Suite', 'Test Set'],
                allTypes = topLevelTypes.concat(['Task', 'Test Case']);
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
            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this);
            }
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

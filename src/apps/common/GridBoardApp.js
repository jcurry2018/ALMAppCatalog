(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.common.GridBoardApp', {
        requires: [
            'Rally.ui.gridboard.GridBoard',
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.ui.grid.plugin.TreeGridExpandedRowPersistence'
        ],
        extend: 'Rally.app.App',

        config: {
            toggleState: 'grid',
            modelNames: [],
            enableGridBoardToggle: false,
            enableAddNew: true,
            enableFilterControl: true,
            enableFieldPicker: true,
            enableOwnerFilter: true,
            persistExpansionState: true
        },

        launch: function () {
            this.loadModelNames().then({
                success: function (modelNames) {
                    this.modelNames = modelNames;

                    if(!this.rendered) {
                        this.on('afterrender', this.loadGridBoard, this, {single: true});
                    } else {
                        this.loadGridBoard();
                    }
                },
                scope: this
            });
        },

        /**
         * @returns {Deft.Promise} Returns a promise which resolves with an array of model types
         */
        loadModelNames: function () {
            return Deft.Promise.when(this.modelNames);
        },

        loadGridBoard: function () {
            if (this.toggleState === 'grid') {
                return this.getGridStore().then({
                    success: function (gridStore) {
                        this.addGridBoard({
                            gridStore: gridStore
                        });
                    },
                    scope: this
                });
            } else {
                return this.getCardBoardColumns().then({
                    success: function (columns) {
                        this.addGridBoard({
                            columns: columns
                        });

                        if (!columns || columns.length === 0) {
                            this.showNoColumns();
                            this.publishComponentReady();
                        }
                    },
                    scope: this
                });
            }
        },

        showNoColumns: function () {
            this.add({
                xtype: 'container',
                cls: 'no-type-text',
                html: '<p>This Type has no states defined.</p>'
            });
        },

        addGridBoard: function (options) {
            this.gridboard = Ext.create('Rally.ui.gridboard.GridBoard', this.getGridBoardConfig(options));
            this.add(this.gridboard);
            this.addHeader();
        },

        addHeader: function () {
            var header = this.gridboard.getHeader();

            if (header) {
                header.getRight().add(this.getHeaderControls());
            }
        },

        getHeaderControls: function () {
            return [];
        },

        getCardBoardColumns: function () {
            return Deft.Promise.when([]);
        },

        getGridStore: function () {
            var storeConfig = _.merge({
                models: _.clone(this.modelNames),
                autoLoad: !this.enableFilterControl,
                remoteSort: true,
                root: {expanded: true},
                pageSize: 200,
                enableHierarchy: true,
                childPageSizeEnabled: true,
                fetch: _.union(this.getAdditionalFetchFields(), this.columnNames)
            }, this.getGridStoreConfig());

            return Ext.create('Rally.data.wsapi.TreeStoreBuilder').build(storeConfig);
        },

        getAdditionalFetchFields: function () {
            return [];
        },

        getGridStoreConfig: function () {
            return {};
        },

        getGridBoardConfig: function (options) {
            return {
                itemId: 'gridboard',
                stateId: this.getStateId() + '-gridboard',
                toggleState: this.toggleState,
                modelNames: _.clone(this.modelNames),
                context: this.getContext(),
                shouldDestroyTreeStore: this.getContext().isFeatureEnabled('S73617_GRIDBOARD_SHOULD_DESTROY_TREESTORE'),
                addNewPluginConfig: _.merge({
                    style: {
                        'float': 'left'
                    }
                }, this.getAddNewConfig()),
                plugins: this.getGridBoardPlugins(),
                cardBoardConfig: this.getCardBoardConfig(options),
                gridConfig: this.getGridConfig(options),
                height: this.getHeight()
            };
        },

        getStateId: function () {
            return this.xtype;
        },

        getGridBoardPlugins: function () {
            var plugins = [];
            if (this.enableAddNew) {
                plugins.push({
                    ptype: 'rallygridboardaddnew',
                    context: this.getContext()
                });
            }
            if (this.enableFilterControl) {
                plugins.push({
                    ptype: 'rallygridboardcustomfiltercontrol',
                    filterChildren: false,
                    filterControlConfig: _.merge({
                        margin: '3 5 3 10',
                        modelNames: this.modelNames,
                        stateful: true,
                        stateId: this.getContext().getScopedStateId(this.getStateId() + '-custom-filter-button')
                    }, this.getFilterControlConfig()),
                    showOwnerFilter: this.enableOwnerFilter,
                    ownerFilterControlConfig: {
                        margin: '3 10 3 10',
                        stateful: true,
                        stateId: this.getContext().getScopedStateId(this.getStateId() + '-owner-filter')
                    }
                });
            }
            if (this.enableFieldPicker) {
                plugins.push(_.merge({
                    ptype: 'rallygridboardfieldpicker',
                    headerPosition: 'left'
                }, this.getFieldPickerConfig()));
            }
            return plugins;
        },

        getGridConfig: function (options) {
            var context = this.getContext();
            return {
                xtype: 'rallytreegrid',
                columnCfgs: this.getColumnCfgs(),
                summaryColumns: [],
                enableBulkEdit: true,
                enableBulkEditMilestones: context.isFeatureEnabled('S70874_SHOW_MILESTONES_PAGE'),
                plugins: this.getGridPlugins(),
                stateId: context.getScopedStateId(this.getStateId() + '-grid'),
                stateful: true,
                alwaysShowDefaultColumns: false,
                listeners: {
                    afterrender: this.publishComponentReady,
                    scope: this
                },
                store: options && options.gridStore,
                bufferedRenderer: this.getContext().isFeatureEnabled('S69537_BUFFERED_RENDERER_TREE_GRID')
            };
        },

        getColumnCfgs: function() {
            return this.getSetting('columnNames') || this.columnNames || [];
        },

        publishComponentReady: function () {
            this.recordComponentReady();

            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this);
            }
        },

        getGridPlugins: function () {
            return this.persistExpansionState ? ['rallytreegridexpandedrowpersistence'] : [];
        },

        getAddNewConfig: function () {
            return {};
        },

        getFilterControlConfig: function () {
            return {};
        },

        getFieldPickerConfig: function () {
            return {
                boardFieldBlackList: [
                    'AcceptedLeafStoryCount',
                    'AcceptedLeafStoryPlanEstimateTotal',
                    'DirectChildrenCount',
                    'LastUpdateDate',
                    'LeafStoryCount',
                    'LeafStoryPlanEstimateTotal',
                    'UnEstimatedLeafStoryCount'
                ],
                gridFieldBlackList: [
                    'ObjectID',
                    'Description',
                    'Notes',
                    'Subscription',
                    'Workspace',
                    'Changesets',
                    'RevisionHistory',
                    'Children',
                    'Successors',
                    'Predecessors'
                ]
            };
        },

        getCardBoardConfig: function () {
            return {};
        },

        getHeight: function () {
            var height = this.callParent(arguments);
            return Ext.isIE8 ? Math.max(height, 600) : height;
        },

        setHeight: function(height) {
            this.callParent(arguments);
            if(this.gridboard) {
                this.gridboard.setHeight(height);
            }
        }
    });
})();
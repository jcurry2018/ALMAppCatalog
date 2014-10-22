(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.taskboard.TaskBoardApp', {
        extend: 'Rally.app.TimeboxScopedApp',
        requires: [
            'Rally.ui.cardboard.plugin.FixedHeader',
            'Rally.ui.gridboard.GridBoard',
            'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.apps.taskboard.TaskBoardHeader'
        ],
        cls: 'taskboard',
        alias: 'widget.taskboardapp',
        appName: 'TaskBoard',
        scopeType: 'iteration',
        supportsUnscheduled: false,
        autoScroll: false,
        layout: 'fit',

        config: {
            defaultSettings: {
                hideAcceptedWork: false
            }
        },

        onScopeChange: function () {
            Ext.create('Rally.data.wsapi.artifact.Store', {
                context: this.getContext().getDataContext(),
                models: ['Defect', 'Defect Suite', 'Test Set', 'User Story'],
                limit: Infinity,
                filters: this._getQueryFilters(true),
                sorters: [
                    {
                        property: this._getRankField(),
                        direction: 'ASC'
                    }
                ],
                autoLoad: true,
                listeners: {
                    load: this._onRowsLoaded,
                    scope: this
                },
                fetch: ['FormattedID']
            });
        },

        onNoAvailableTimeboxes: function() {
            this._destroyGridBoard();
        },

        getSettingsFields: function () {
            var fields = this.callParent(arguments);

            fields.push({
                name: 'hideAcceptedWork',
                xtype: 'rallycheckboxfield',
                margin: '10 0 0 0',
                boxLabel: 'Hide accepted work',
                fieldLabel: ' '
            });

            return fields;
        },

        _destroyGridBoard: function() {
            var gridBoard = this.down('rallygridboard');
            if (gridBoard) {
                gridBoard.destroy();
            }
        },

        _onRowsLoaded: function (store) {
            this._destroyGridBoard();
            this.add(this._getGridBoardConfig(store.getRange()));
        },

        _getBoard: function () {
            return this.down('rallygridboard').getGridOrBoard();
        },

        _getGridBoardConfig: function (rowRecords) {
            var context = this.getContext(),
                modelNames = ['Task'];
            return {
                xtype: 'rallygridboard',
                stateful: false,
                toggleState: 'board',
                cardBoardConfig: this._getBoardConfig(rowRecords),
                shouldDestroyTreeStore: this.getContext().isFeatureEnabled('S73617_GRIDBOARD_SHOULD_DESTROY_TREESTORE'),
                plugins: [
                    'rallygridboardaddnew',
                    {
                        ptype: 'rallygridboardcustomfiltercontrol',
                        filterChildren: false,
                        filterControlConfig: {
                            margin: '3 9 3 30',
                            modelNames: modelNames,
                            stateful: true,
                            stateId: context.getScopedStateId('taskboard-custom-filter-button')
                        },
                        showOwnerFilter: true,
                        ownerFilterControlConfig: {
                            stateful: true,
                            stateId: context.getScopedStateId('taskboard-owner-filter')
                        }
                    },
                    {
                        ptype: 'rallygridboardfieldpicker',
                        headerPosition: 'left',
                        modelNames: modelNames,
                        boardFieldDefaults: ['Estimate', 'ToDo'],
                        boardFieldBlackList: ['State']
                    }
                ],
                context: context,
                modelNames: modelNames,
                storeConfig: {
                    filters: this._getQueryFilters(false),
                    enableRankFieldParameterAutoMapping: false
                },
                addNewPluginConfig: {
                    style: {
                        'float': 'left'
                    },
                    recordTypes: ['Task', 'Defect', 'Defect Suite', 'Test Set', 'User Story'],
                    additionalFields: [this._createWorkProductComboBox(rowRecords)],
                    listeners: {
                        recordtypechange: this._onAddNewRecordTypeChange,
                        create: this._onAddNewCreate,
                        scope: this
                    },
                    minWidth: 600,
                    ignoredRequiredFields: ['Name', 'Project', 'WorkProduct', 'State', 'TaskIndex', 'ScheduleState']
                },
                height: this.getHeight()
            };
        },

        _getRankField: function() {
            return this.getContext().getWorkspace().WorkspaceConfiguration.DragDropRankingEnabled ?
                Rally.data.Ranker.RANK_FIELDS.DND :
                Rally.data.Ranker.RANK_FIELDS.MANUAL;
        },

        _onAddNewCreate: function (addNew, record) {
            if (!record.isTask()) {
                this._getBoard().addRow(record.getData());
                this._workProductCombo.getStore().add(record);
            }
        },

        _onAddNewRecordTypeChange: function (addNew, value) {
            this._workProductCombo.setVisible(value === 'Task');
        },

        _createWorkProductComboBox: function (rowRecords) {
            this._workProductCombo = Ext.create('Rally.ui.combobox.ComboBox', {
                displayField: 'FormattedID',
                valueField: '_ref',
                store: Ext.create('Ext.data.Store', {
                    data: _.invoke(rowRecords, 'getData'),
                    fields: ['_ref', 'FormattedID']
                }),
                emptyText: 'Work Product',
                defaultSelectionPosition: null,
                allowBlank: false,
                validateOnChange: false,
                validateOnBlur: false,
                name: 'WorkProduct',
                itemId: 'workProduct'
            });
            return this._workProductCombo;
        },

        _getBoardConfig: function (rowRecords) {
            return {
                xtype: 'rallycardboard',
                attribute: 'State',
                rowConfig: {
                    field: 'WorkProduct',
                    sorters: [
                        {
                            property: this._getRankField(),
                            direction: 'ASC'
                        },
                        {
                            property: 'TaskIndex',
                            direction: 'ASC'
                        }
                    ],
                    values: _.pluck(rowRecords, 'data'),
                    headerConfig: {
                        xtype: 'rallytaskboardrowheader'
                    }
                },
                margin: '10px 0 0 0',
                plugins: [{ptype:'rallyfixedheadercardboard'}]
            };
        },

        _getQueryFilters: function (isRoot) {
            var timeboxFilters = [this.getContext().getTimeboxScope().getQueryFilter()];
            if(this.getSetting('hideAcceptedWork')) {
                if (isRoot) {
                    timeboxFilters.push({
                        property: 'ScheduleState',
                        operator: '<',
                        value: 'Accepted'
                    });
                } else {
                    timeboxFilters.push({
                        property: 'WorkProduct.ScheduleState',
                        operator: '<',
                        value: 'Accepted'
                    });
                }
            }
            return timeboxFilters;
        }
    });
})();
(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.board.BoardApp', {
        extend: 'Rally.app.App',
        alias: 'widget.boardapp',

        requires: [
            'Rally.ui.cardboard.plugin.FixedHeader',
            'Rally.ui.gridboard.GridBoard',
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.data.util.Sorter',
            'Rally.apps.board.Settings',
            'Rally.clientmetrics.ClientMetricsRecordable'
        ],
        mixins: [
            'Rally.clientmetrics.ClientMetricsRecordable'
        ],

        cls: 'customboard',
        autoScroll: false,
        layout: 'fit',

        config: {
            defaultSettings: {
                type: 'HierarchicalRequirement',
                groupByField: 'ScheduleState',
                query: '',
                order: 'Rank',
                showRows: false
            }
        },

        launch: function() {
            Rally.data.ModelFactory.getModel({
                type: this.getSetting('type'),
                context: this.getContext().getDataContext()
            }).then({
                success: function (model) {
                    this.model = model;
                    this.add(this._getGridBoardConfig());
                },
                scope: this
            });
        },

        _getGridBoardConfig: function() {
            var context = this.getContext(),
                modelNames = [this.getSetting('type')],
                config = {
                    xtype: 'rallygridboard',
                    stateful: false,
                    toggleState: 'board',
                    cardBoardConfig: this._getBoardConfig(),
                    plugins: [
                        'rallygridboardaddnew',
                        {
                            ptype: 'rallygridboardcustomfiltercontrol',
                            filterChildren: false,
                            filterControlConfig: {
                                margin: '3 9 3 30',
                                modelNames: modelNames,
                                stateful: true,
                                stateId: context.getScopedStateId('board-custom-filter-button')
                            },
                            showOwnerFilter: true,
                            ownerFilterControlConfig: {
                                stateful: true,
                                stateId: context.getScopedStateId('board-owner-filter')
                            }
                        },
                        {
                            ptype: 'rallygridboardfieldpicker',
                            headerPosition: 'left',
                            boardFieldBlackList: ['Successors', 'Predecessors', 'DisplayColor'],
                            modelNames: modelNames,
                            boardFieldDefaults: (this.getSetting('fields')
                                && this.getSetting('fields').split(',')) || []
                        }
                    ],
                    context: context,
                    modelNames: modelNames,
                    addNewPluginConfig: {
                        style: {
                            'float': 'left'
                        }
                    },
                    storeConfig: {
                        filters: this._getFilters()
                    },
                    listeners: {
                        load: this._onLoad,
                        scope: this
                    }
                };
            if(this.getEl()) {
                config.height = this.getHeight();
            }
            return config;
        },

        _onLoad: function() {
            this.recordComponentReady({
                miscData: {
                    type: this.getSetting('type'),
                    columns: this.getSetting('groupByField'),
                    rows: (this.getSetting('showRows') && this.getSetting('rowsField')) || ''
                }
            });
        },

        _getBoardConfig: function() {
            var boardConfig = {
                margin: '10px 0 0 0',
                attribute: this.getSetting('groupByField'),
                context: this.getContext(),
                cardConfig: {
                    editable: true,
                    showIconMenus: true
                },
                loadMask: true,
                plugins: [{ptype:'rallyfixedheadercardboard'}]
            };
            if (this.getSetting('showRows')) {
                Ext.merge(boardConfig, {
                    rowConfig: {
                        field: this.getSetting('rowsField'),
                        sortDirection: 'ASC'
                    }
                });
            } else {
                Ext.merge(boardConfig, {
                    storeConfig: {
                        sorters: Rally.data.util.Sorter.sorters(this.getSetting('order'))
                    }
                });
            }
            return boardConfig;
        },

        getSettingsFields: function() {
            return Rally.apps.board.Settings.getFields(this.getContext());
        },

        _addBoard: function() {
            var gridBoard = this.down('rallygridboard');
            if(gridBoard) {
                gridBoard.destroy();
            }
            this.add(this._getGridBoardConfig());
        },

        onTimeboxScopeChange: function(timeboxScope) {
            this.callParent(arguments);
            this._addBoard();
        },

        _getFilters: function() {
            var queries = [],
                timeboxScope = this.getContext().getTimeboxScope();
            if (this.getSetting('query')) {
                queries.push(Rally.data.QueryFilter.fromQueryString(this.getSetting('query')));
            }
            if (timeboxScope && this.model.hasField(Ext.String.capitalize(timeboxScope.getType()))) {
                queries.push(timeboxScope.getQueryFilter());
            }

            return queries;
        }
    });
})();

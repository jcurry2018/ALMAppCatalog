(function() {
    var Ext = window.Ext4 || window.Ext;

    //TODO: update screenshot when done
    //TODO: update github src link when done
    Ext.define('Rally.apps.taskboard.TaskBoardApp', {
        extend: 'Rally.app.TimeboxScopedApp',
        requires: [
            'Rally.ui.gridboard.GridBoard',
            'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.ui.gridboard.plugin.GridBoardAddNew'
        ],
        cls: 'taskboard',
        alias: 'widget.taskboardapp',
        appName: 'TaskBoard',
        scopeType: 'iteration',

        onScopeChange: function() {
            var gridBoard = this.down('rallygridboard');
            if(gridBoard) {
                gridBoard.destroy();
            }
            this.add(this._getGridBoardConfig());
        },

        _getGridBoardConfig: function() {
            var context = this.getContext(),
                modelNames = ['Task'];
            return {
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
                        alwaysSelectedValues: ['FormattedID', 'Name', 'Owner', 'BlockedReason'],
                        modelNames: modelNames,
                        boardFieldDefaults: [] //todo: what fields to show on cards by default?
                    }
                ],
                context: context,
                modelNames: ['Task'],
                storeConfig: {
                    filters: this._getQueryFilters()
                },
                addNewPluginConfig: {
                    style: {
                        'float': 'left'
                    },
                    recordTypes: ['User Story', 'Defect', 'Task']
                    //todo: need to add an additional combobox to pick which story or defect to associate new task with
                    //todo: when adding a defect or story need to add a new swimlane for that item
                }
            };
        },

        _getBoardConfig: function() {
            return {
                xtype: 'rallycardboard',
                attribute: 'State',
                rowConfig: {
                    field: 'WorkProduct'
                    //TODO: figure out how to sort rows by rank via wsapi
                    //TODO: work with alex to render data in the header for the work product rather than just the name.  new rowHeaderConfig?
                    //TODO: should we allow moving tasks between work products?
                }
            };
        },

        _getQueryFilters: function() {
            return [this.getContext().getTimeboxScope().getQueryFilter()];
        }
    });
})();

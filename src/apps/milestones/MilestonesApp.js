(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.milestones.MilestonesApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.ui.DateField',
            'Rally.ui.combobox.MilestoneProjectComboBox',
            'Rally.ui.grid.MilestoneProjectEditor',
            'Rally.ui.grid.RowActionColumn',
            'Rally.ui.menu.item.DeleteMenuItem'
        ],
        cls: 'milestones-app',

        launch: function() {
            var context = this.getContext();
            this.add(Ext.create('Rally.ui.list.ListView', {
                model: Ext.identityFn('milestone'),
                addNewConfig: this._addNewConfig(),
                gridConfig: {
                    columnCfgs: [
                        {
                            xtype: 'rallyrowactioncolumn',
                            rowActionsFn: function (record) {
                                return [
                                    {
                                        xtype: 'rallyrecordmenuitemdelete',
                                        record: record
                                    }
                                ];
                            }
                        },
                        {
                            dataIndex: 'FormattedID',
                            renderer: function(formattedID, obj, record) {
                                return Ext.create('Rally.ui.renderer.template.FormattedIDTemplate').apply({
                                   _type: 'milestone',
                                   FormattedID: formattedID,
                                   DisplayColor: record.get('DisplayColor'),
                                   Recycled: true
                                });
                            }
                        },
                        {
                            dataIndex: 'DisplayColor',
                            width: 60,
                            text: 'Color'
                        },
                        'Name',
                        'TargetDate',
                        {
                            dataIndex: 'TotalArtifactCount',
                            text: 'Item Count',
                            tdCls: 'artifacts'
                        },
                        {
                            dataIndex: 'TargetProject',
                            isCellEditable: function(project){
                                return !Rally.ui.grid.MilestoneProjectEditor.shouldDisableEditing(project);
                            },
                            renderer: function(project) {
                                if (project === ''){
                                    return '<div class="permission-required">Project Permissions Required</div>';
                                }
                                if (project === null) {
                                    return 'All projects in ' +  context.getWorkspace().Name;
                                }
                                return project.Name;
                            },
                            text: 'Project'
                        }
                    ],
                    enableRanking: true,
                    storeConfig: {
                        fetch: 'FormattedID,Name,TargetDate,Artifacts,TargetProject,TotalArtifactCount',
                        sorters: [{
                            property: 'TargetDate',
                            direction: 'DESC'
                        }]
                    },
                    showRowActionsColumn: false,
                    viewConfig: {
                        emptyText: this._getEmptyText()
                    },
                    showIcon: false
                }
            }));
        },

        _addNewConfig: function() {
            return this.context.getPermissions().hasEditorAccessToAnyProject() ? {
                recordTypes: ['Milestone'],
                showAddWithDetails: false,
                openEditorAfterAddFailure: false,
                minWidth: 800,
                additionalFields: [
                    {
                        xtype: 'rallydatefield',
                        emptyText: 'Select Date',
                        name: 'TargetDate'
                    },
                    {
                        xtype: 'rallymilestoneprojectcombobox',
                        minWidth: 250,
                        name: 'TargetProject',
                        value: Rally.util.Ref.getRelativeUri(this.getContext().getProject())
                    }
                ]
            } : {};
        },

        _getEmptyText: function() {
            return '<div class="no-data-container"><div class="primary-message">Looks like no milestones have been created.</div><div class="secondary-message">Add a milestone with the Add New button above.</div></div>';
        }
    });
})();
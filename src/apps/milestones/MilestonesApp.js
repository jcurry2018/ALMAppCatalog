(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.milestones.MilestonesApp', {
        extend: 'Rally.app.App',
        requires: [],
        cls: 'milestones-app',

        launch: function() {
            var context = this.getContext();
            this.add(Ext.create('Rally.ui.list.ListView', {
                model: Ext.identityFn('milestone'),
                addNewConfig: this._addNewConfig(),
                gridConfig: {
                    columnCfgs: [
                        {
                            dataIndex: 'FormattedID',
                            renderer: function(formattedID) {
                                return Ext.create('Rally.ui.renderer.template.FormattedIDTemplate').apply({
                                   _type: 'milestone',
                                   FormattedID: formattedID,
                                   Recycled: true
                                });
                            }
                        },
                        'Name',
                        'TargetDate',
                        {
                            dataIndex: 'Artifacts',
                            renderer: function(artifactsCollection) {
                                return artifactsCollection.Count;
                            },
                            text: 'Item Count'
                        },
                        {
                            dataIndex: 'TargetProject',
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
                        fetch: 'FormattedID,Name,TargetDate,Artifacts,TargetProject',
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
            if (this.context.getPermissions().isProjectEditor(this.context.getProjectRef())) {
                return {
                    recordTypes: ['Milestone'],
                    showAddWithDetails: false,
                    openEditorAfterAddFailure: false,
                    minWidth: 800
                };
            }
            return {};
        },

        _getEmptyText: function() {
            return '<div class="no-data-container"><div class="primary-message">Looks like milestones have not yet been defined for the current project.</div><div class="secondary-message">Add a milestone with the Add New button above.</div></div>';
        }
    });
})();
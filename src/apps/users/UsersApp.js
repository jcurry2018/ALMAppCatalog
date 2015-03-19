(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.users.UsersApp', {
        extend: 'Rally.app.GridBoardApp',
        requires: [
            'Rally.apps.users.SubscriptionSeats',
            'Rally.data.wsapi.ModelFactory',
            'Rally.ui.combobox.plugin.PreferenceEnabledComboBox',
            'Rally.util.Ref'
        ],

        cls: 'users-app',
        isWorkspaceScoped: true,
        modelNames: ['User'],
        scopeOfUserPrefs: 'subscription',
        statePrefix: 'users',

        addGridBoard: function () {
            if (this.gridboard && this.workspacePicker && this.workspacePicker.rendered) {
                this.workspacePicker.up().remove(this.workspacePicker, false);
            }

            this.callParent(arguments);

            var leftHeader = this.gridboard.getHeader().getLeft();
            leftHeader.insert(leftHeader.items.indexOf(leftHeader.down('#gridBoardFilterControlCt')) + 1, this.workspacePicker);
            leftHeader.add({xtype: 'rallysubscriptionseats'});
        },

        getGridConfig: function () {
            return _.merge(this.callParent(arguments), {
                enableBulkEdit: false,
                rowActionColumnConfig: {
                    menuOptions: {
                        showInlineAdd: false
                    }
                }
            });
        },

        getPermanentFilters: function () {
            return this._getSelectedWorkspace() ? [{ property: 'WorkspacePermission', operator: '!=', value: 'No Access' }] : [];
        },

        getScopedStateId: function (suffix) {
            return Ext.create('Rally.state.ScopedStateUtil').getScopedStateId(this.getStateId(suffix), {
                appID: this.getContext().getAppId(),
                filterByUser: true
            });
        },

        loadModelNames: function () {
            return this._createWorkspacePicker().then({
                success: function() {
                    this.workspacePicker.on('select', this._onWorkspaceSelect, this);
                    this._setWorkspaceOnContext();
                    return this.modelNames;
                },
                scope: this
            });
        },

        _createWorkspacePicker: function () {
            var deferred = new Deft.Deferred();

            this.workspacePicker = Ext.create('Rally.ui.combobox.ComboBox', {
                allowClear: true,
                autoExpand: true,
                clearText: '-- Clear Filter --',
                cls:'user-workspace-picker',
                context: this.getContext(),
                editable: false,
                emptyText: 'Filter by Workspace',
                itemId: 'userWorkspacePicker',
                listeners: {
                    ready: {
                        fn: function() {
                            deferred.resolve();
                        },
                        single: true
                    },
                    scope: this
                },
                plugins: [{
                    ptype: 'rallypreferenceenabledcombobox',
                    preferenceName: this.getScopedStateId('workspace-combobox')
                }],
                storeConfig: {
                    autoLoad: true,
                    filters: [{property: 'State', value: 'Open'}],
                    limit: Infinity,
                    model: Ext.identityFn('Workspace'),
                    proxy: Rally.data.wsapi.ModelFactory.buildProxy(Rally.environment.getServer().getContextPath() + '/webservice/v2.x/workspaces/admin', 'workspace', null, 'v2.x'),
                    sorters: {
                        property: 'Name',
                        direction: 'ASC'
                    }
                }
            });
            return deferred.promise;
        },

        _getSelectedWorkspace: function() {
            return this.workspacePicker.getStore().findRecord('_ref', this.workspacePicker.getValue());
        },

        _onWorkspaceSelect: function() {
            this._setWorkspaceOnContext();
            this.loadGridBoard();
        },

        _setWorkspaceOnContext: function() {
            this.context = this.getContext().clone();
            this.context.setWorkspace(this._getSelectedWorkspace() ? this._getSelectedWorkspace().data : Rally.environment.getContext().getWorkspace());
        },

        getGridBoardCustomFilterControlConfig: function() {
            return {
                showUserFilter: true,
                userFilterConfig: {
                    stateful: true,
                    stateId: this.getScopedStateId('user-user-filter'),
                    storeConfig:{
                        pageSize: 25,
                        fetch: ['UserName'],
                        autoLoad: true
                    }
                }
            };
        }
    });
})();
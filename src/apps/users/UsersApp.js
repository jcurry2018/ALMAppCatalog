(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.users.UsersApp', {
        extend: 'Rally.app.GridBoardApp',
        requires: ['Rally.data.wsapi.ModelFactory'],

        cls: 'users-app',
        isWorkspaceScoped: true,
        modelNames: ['User'],
        statePrefix: 'users',

        addGridBoard: function () {
            if (this.gridboard && this.workspacePicker && this.workspacePicker.rendered) {
                this.workspacePicker.up().remove(this.workspacePicker, false);
            }

            this.callParent(arguments);

            var leftHeader = this.gridboard.getHeader().getLeft();
            leftHeader.insert(leftHeader.items.indexOf(leftHeader.down('#gridBoardFilterControlCt')) + 1, this.workspacePicker);

            var seatInfoCtId = 'seatInformationMessage';
            leftHeader.add({
                xtype: 'component',
                cls: 'license-count',
                id: seatInfoCtId,
                width: 200
            });
            Ext.create('Rally.apps.users.SubscriptionSeats', {
                targetId: seatInfoCtId,
                workspaceOid: this.getContext().getWorkspace().ObjectID
            });
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

        loadModelNames: function () {
            return this._createWorkspacePicker().then({
                success: function() {
                    this.workspacePicker.on('change', this._onWorkspaceChanged, this);
                    this._setWorkspaceOnContext();
                    return this.modelNames;
                },
                scope: this
            });
        },

        _createWorkspacePicker: function () {
            var deferred = new Deft.Deferred();

            this.workspacePicker = Ext.create('Rally.ui.combobox.PreferenceEnabledComboBox', {
                allowClear: true,
                autoExpand: true,
                clearText: '-- Clear Filter --',
                cls:'user-workspace-picker',
                context: this.getContext(),
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
                preferenceName: this.getStateId('workspace-combobox'),
                storeConfig: {
                    fetch: 'Name,ObjectID',
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

        _onWorkspaceChanged: function() {
            this._setWorkspaceOnContext();
            this.loadGridBoard();
        },

        _setWorkspaceOnContext: function() {
            this.context = this.getContext().clone();
            this.context.setWorkspace(this._getSelectedWorkspace() ? this._getSelectedWorkspace().data : Rally.environment.getContext().getWorkspace());
        }
    });
})();
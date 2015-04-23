(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.customlist.CustomListApp', {
        extend: 'Rally.app.GridBoardApp',
        requires: [
            'Deft.Promise',
            'Rally.apps.customlist.Settings',
            'Rally.data.ModelTypes',
            'Rally.data.util.Sorter',
            'Rally.data.wsapi.Filter',
            'Rally.ui.notify.Notifier'
        ],

        disallowedAddNewTypes: ['user', 'userprofile', 'useriterationcapacity', 'testcaseresult', 'task', 'scmrepository', 'project', 'changeset', 'change', 'builddefinition', 'build', 'program'],
        orderedAllowedPageSizes: [10, 25, 50, 100, 200],
        readOnlyGridTypes: ['build', 'change', 'changeset'],
        statePrefix: 'customlist',
        allowExpansionStateToBeSaved: false,

        initComponent: function () {
            this.appName = 'CustomList-' + this.getAppId();
            this.defaultSettings = {
                columnNames: (this.appContainer.fetch || '').split(','),
                order: this.appContainer.order,
                query: this.appContainer.query,
                showControls: true,
                type: this.appContainer.url
            };
            this.callParent(arguments);
        },

        getSettingsFields: function() {
            return Rally.apps.customlist.Settings.getFields(this.getContext());
        },

        loadModelNames: function () {
            this.modelNames = _.compact([this.getSetting('type')]);
            this._setColumnNames(this.getSetting('columnNames'));
            return Deft.Promise.when(this.modelNames);
        },

        addGridBoard: function () {
            this.callParent(arguments);

            if (!this.getSetting('showControls')) {
                this.gridboard.getHeader().hide();
            }
        },

        loadGridBoard: function () {
            if (_.isEmpty(this.modelNames)) {
                Ext.defer(function () {
                    this.owner.showSettings();
                    this.publishComponentReady();
                }, 1, this);
            } else {
                this.enableAddNew = this._shouldEnableAddNew();
                this.enableRanking = this._shouldEnableRanking();
                this.callParent(arguments);
            }
        },

        getGridConfig: function () {
            return _.merge(this.callParent(arguments), {
                enableEditing: !_.contains(this.readOnlyGridTypes, this.getSetting('type').toLowerCase()),
                listeners: {
                    beforestaterestore: this._onBeforeGridStateRestore,
                    beforestatesave: this._onBeforeGridStateSave,
                    scope: this
                },
                pagingToolbarCfg: {
                    hidden: !this.getSetting('showControls'),
                    pageSizes: this.orderedAllowedPageSizes
                }
            });
        },

        getFilterControlConfig: function () {
            return _.merge(this.callParent(arguments), {
                listeners: {
                    beforestaterestore: {
                        fn: this._onBeforeFilterButtonStateRestore,
                        scope: this
                    }
                }
            });
        },

        onTreeGridReady: function (grid) {
            if (grid.store.getTotalCount() > 10) {
                this.gridboard.down('#pagingToolbar').show();
            }

            this.callParent(arguments);
        },

        getGridStoreConfig: function () {
            var sorters = this._getValidSorters(Rally.data.util.Sorter.sorters(this.getSetting('order')));

            if (_.isEmpty(sorters)) {
                var rankField = this.getContext().getWorkspace().WorkspaceConfiguration.DragDropRankingEnabled ? 'DragAndDropRank' : 'Rank';
                var defaultSort = Rally.data.ModelTypes.areArtifacts(this.modelNames) ? rankField : Rally.data.util.Sorter.getDefaultSort(this.modelNames[0]);

                sorters = Rally.data.util.Sorter.sorters(defaultSort);
            }

            return {
                pageSize: this.appContainer.pagesize ? _.find(this.orderedAllowedPageSizes, function(pageSize, index, array){
                    return pageSize >= parseInt(this.appContainer.pagesize, 10) || index === array.length - 1;
                }, this) : 10,
                sorters: sorters
            };
        },

        getAddNewConfig: function () {
            return _.merge(this.callParent(arguments), {
                disableAddButton: this.appContainer.slug === 'incompletestories',
                minWidth: 700,
                openEditorAfterAddFailure: false
            });
        },

        getFieldPickerConfig: function () {
            return _.merge(this.callParent(arguments), {
                buttonConfig: {
                    disabled: !this._userHasPermissionsToEditPanelSettings()
                }
            });
        },

        getPermanentFilters: function () {
            return this._getQueryFilter().concat(this._getTimeboxScopeFilter()).concat(this._getProjectFilter());
        },

        onTimeboxScopeChange: function() {
            this.callParent(arguments);
            this.loadGridBoard();
        },

        _getQueryFilter: function () {
            var query = new Ext.Template(this.getSetting('query')).apply({
                projectName: this.getContext().getProject().Name,
                projectOid: this.getContext().getProject().ObjectID,
                user: this.getContext().getUser()._ref
            });
            if (query) {
                try {
                    return [ Rally.data.wsapi.Filter.fromQueryString(query) ];
                } catch(e) {
                    Rally.ui.notify.Notifier.showError({ message: e.message });
                }
            }
            return [];
        },

        _getProjectFilter: function () {
            return this.modelNames[0].toLowerCase() === 'milestone' ? [
                Rally.data.wsapi.Filter.or([
                    { property: 'Projects', operator: 'contains', value: this.getContext().getProjectRef() },
                    { property: 'TargetProject', operator: '=', value: null }
                ])
            ] : [];
        },

        _getTimeboxScopeFilter: function () {
            var timeboxScope = this.getContext().getTimeboxScope();
            var hasTimeboxField = timeboxScope && _.any(this.models, function (model) {
                return model.hasField(Ext.String.capitalize(timeboxScope.getType()));
            });
            return hasTimeboxField ? [ timeboxScope.getQueryFilter() ] : [];
        },

        _shouldEnableAddNew: function() {
            return !_.contains(this.disallowedAddNewTypes, this.getSetting('type').toLowerCase());
        },

        _shouldEnableRanking: function(){
            return this.getSetting('type').toLowerCase() !== 'task';
        },

        _setColumnNames: function (columnNames) {
            this.columnNames = _.compact(_.isString(columnNames) ? columnNames.split(',') : columnNames);
        },

        _onBeforeFilterButtonStateRestore:  function (filterButton, state) {
            if (state && state.filters && state.filters.length) {
                var stateFilters = _.map(state.filters, function (filterStr) {
                    return Rally.data.wsapi.Filter.fromQueryString(filterStr);
                });
                var validFilters = Rally.util.Filter.removeNonapplicableTypeSpecificFilters(stateFilters, this.models);
                state.filters = _.invoke(validFilters, 'toString');
            }
        },

        _onBeforeGridStateRestore: function (grid, state) {
            if (!state) {
                return;
            }

            if (state.columns) {
                var appScopedColumnNames = this.getColumnCfgs();
                var userScopedColumnNames = this._getColumnNamesFromState(state);

                if(_.difference(appScopedColumnNames, userScopedColumnNames).length > 0) {
                    state.columns = appScopedColumnNames;
                } else {
                    state.columns = _.filter(state.columns, function (column) {
                        return _.contains(appScopedColumnNames, _.isObject(column) ? column.dataIndex : column);
                    });
                }
            }

            if (state.sorters) {
                state.sorters = this._getValidSorters(state.sorters);
                if (_.isEmpty(state.sorters)) {
                    delete state.sorters;
                }
            }
        },

        _onBeforeGridStateSave: function (grid, state) {
            var newColumnNames = this._getColumnNamesFromState(state);

            if (!_.isEmpty(newColumnNames)) {
                this._setColumnNames(newColumnNames);

                if (this._userHasPermissionsToEditPanelSettings()) {
                    this.updateSettingsValues({
                        settings: {
                            columnNames: newColumnNames.join(',')
                        }
                    });
                }
            }
        },

        _getValidSorters: function (sorters) {
            return _.filter(sorters, function (sorter) {
                return _.any(this.models, function (model) {
                    var field = model.getField(sorter.property);
                    return field && field.sortable;
                });
            }, this);
        },

        _userHasPermissionsToEditPanelSettings: function () {
            return this.owner.dashboard.arePanelSettingsEditable;
        },

        _getColumnNamesFromState: function (state) {
            return _(state && state.columns).map(function (newColumn) {
                return _.isObject(newColumn) ? newColumn.dataIndex : newColumn;
            }).compact().value();
        }
    });
})();

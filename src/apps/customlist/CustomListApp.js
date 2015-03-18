(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.customlist.CustomListApp', {
        extend: 'Rally.app.GridBoardApp',
        requires: [
            'Deft.Promise',
            'Rally.apps.customlist.Settings',
            'Rally.data.ModelTypes',
            'Rally.data.util.Sorter',
            'Rally.data.wsapi.Filter'
        ],

        statePrefix: 'customlist',
        disallowedAddNewTypes: ['user', 'userprofile', 'useriterationcapacity', 'testcaseresult', 'task', 'scmrepository', 'project', 'changeset', 'change', 'builddefinition', 'build'],

        initComponent: function () {
            this.defaultSettings = {
                query: this.appContainer.query,
                order: this.appContainer.order,
                type: this.appContainer.url,
                columnNames: (this.appContainer.fetch || '').split(',')
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

        loadGridBoard: function () {
            if (_.isEmpty(this.modelNames)) {
                Ext.defer(function () {
                    this.owner.showSettings();
                    this.publishComponentReady();
                }, 1, this);
            } else {
                this.enableAddNew = this._shouldEnableAddNew();
                this.callParent(arguments);
            }
        },

        getGridConfig: function () {
            return _.merge(this.callParent(arguments), {
                listeners: {
                    beforestaterestore: this._onBeforeGridStateRestore,
                    beforestatesave: this._onBeforeGridStateSave,
                    scope: this
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

        getGridStoreConfig: function () {
            var sorters = this._getValidSorters(Rally.data.util.Sorter.sorters(this.getSetting('order')));

            if (_.isEmpty(sorters)) {
                var rankField = this.getContext().getWorkspace().WorkspaceConfiguration.DragDropRankingEnabled ? 'DragAndDropRank' : 'Rank';
                var defaultSort = Rally.data.ModelTypes.areArtifacts(this.modelNames) ? rankField : Rally.data.util.Sorter.getDefaultSort(this.modelNames[0]);

                sorters = Rally.data.util.Sorter.sorters(defaultSort);
            }

            return _.merge({
                sorters: sorters
            }, this.appContainer.pagesize ? { pageSize: this.appContainer.pagesize } : {});
        },

        getAddNewConfig: function () {
            return _.merge(this.callParent(arguments), {
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
            var projectFilter = this.getSetting('type').toLowerCase() === 'milestone' ? [
                Rally.data.wsapi.Filter.or([
                    { property: 'Projects', operator: 'contains', value: this.getContext().getProjectRef() },
                    { property: 'TargetProject', operator: '=', value: null }
                ])
            ] : null;

            var query = this.getSetting('query');
            var timeboxScopeFilter = this._getTimeboxScopeFilter().concat(query ? [ Rally.data.wsapi.Filter.fromQueryString(query) ] : []);
            return projectFilter ? projectFilter.concat(timeboxScopeFilter) : timeboxScopeFilter;
        },

        onTimeboxScopeChange: function() {
            this.callParent(arguments);
            this.loadGridBoard();
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

        _setColumnNames: function (columnNames) {
            columnNames = _.isString(columnNames) ? columnNames.split(',') : columnNames;

            // Note: When enableHierarchy is true (artifacts only for now), the FormattedID column is always added
            // If we include FormattedID in columns names, we get 2 ID columns, which is poopy.
            // This problem should be fixed for reals in the SDK somewhere eventually.
            if (Rally.data.ModelTypes.areArtifacts(this.modelNames)) {
                columnNames = _.reject(columnNames, function (columnName) {
                    return _.isString(columnName) && columnName.toLowerCase() === 'formattedid';
                });
            }

            this.columnNames = _.compact(columnNames);
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

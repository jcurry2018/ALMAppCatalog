(function () {
    var Ext = window.Ext4 || window.Ext;

    var appIDMap = {
        milestone: -200004,
        iteration: -200013,
        release: -200012
    };

    Ext.define('Rally.apps.timeboxes.TimeboxesApp', {
        extend: 'Rally.app.GridBoardApp',
        requires: [
            'Deft.Deferred',
            'Rally.apps.timeboxes.IterationVelocityA0Chart',
            'Rally.data.PreferenceManager',
            'Rally.ui.combobox.plugin.PreferenceEnabledComboBox',
            'Rally.ui.gridboard.GridBoardToggle'
        ],

        enableGridBoardToggle: true,

        listeners: {
            gridboardadded: function(gridboard) {
                if (this.selectedType !== 'milestone') {
                    gridboard.on('load', function() {
                        var grid = gridboard.getGridOrBoard();
                        grid.on('storedatachanged', function(store) {
                            if (!_.isEmpty(store.getUpdatedRecords())) {
                                store.suspendEvents();
                                store.load();
                                store.resumeEvents();
                            }
                        }, this);
                    });
                }
            }
        },

        xmlExportEnabled: function(){
            return this.selectedType !== 'milestone';
        },

        loadSettingsAndLaunch: function () {
            if (this.modelPicker) {
                this.callParent(arguments);
            } else {
                this._createPicker().then({
                    success: function (selectedType) {
                        this.changeModelType(selectedType);
                    },
                    scope: this
                });
            }
        },

        changeModelType: function (newType) {
            this.context = this.getContext().clone({
                appID: appIDMap[newType]
            });
            this.selectedType = newType;
            this.modelNames = [newType];
            this.statePrefix = newType;
            this.loadSettingsAndLaunch();
        },

        getGridBoardTogglePluginConfig: function () {
            return _.merge(this.callParent(arguments), {
                autoRefreshComponentOnToggle: false,
                toggleButtonConfig: {
                    showBoardToggle: false,
                    showChartToggle: this._enableCharts() ? true : Rally.ui.gridboard.GridBoardToggle.BUTTON_DISABLED
                }
            });
        },

        getChartConfig: function () {
            if (this._enableCharts()) {
                return {
                    xtype: 'rallyiterationvelocitya0chart'
                };
            }
        },

        getFieldPickerConfig: function () {
            var config = this.callParent(arguments);

            if (this.selectedType === 'milestone') {
                config.gridFieldBlackList = _.union(config.gridFieldBlackList, [
                    'Artifacts',
                    'CreationDate',
                    'Projects',
                    'VersionId'
                ]);
                return _.merge(config, {
                    gridAlwaysSelectedValues: ['TargetDate', 'TotalArtifactCount', 'TargetProject']
                });
            }

            return config;
        },

        getPermanentFilters: function () {
            return this.selectedType === 'milestone' ? [
                Rally.data.wsapi.Filter.or([
                    { property: 'Projects', operator: 'contains', value: this.getContext().getProjectRef() },
                    { property: 'TargetProject', operator: '=', value: null }
                ])
            ] : [];
        },

        getAddNewConfig: function () {
            return _.merge(this.callParent(arguments), {
                minWidth: 800,
                openEditorAfterAddFailure: false,
                showAddWithDetails: true,
                showRank: false
            });
        },

        getGridStoreConfig: function() {
            return _.merge(this.callParent(arguments), {
                sorters: [ {property: this._getStartDateFieldName(), direction: 'DESC'} ]
            });
        },

        _getStartDateFieldName: function () {
            return {
                milestone: 'TargetDate',
                iteration: 'StartDate',
                release: 'ReleaseStartDate'
            }[this.selectedType];
        },

        _enableCharts: function () {
            return this.selectedType ===  'iteration';
        },

        _createPicker: function () {
            var deferred = new Deft.Deferred();

            this.modelPicker = Ext.create('Rally.ui.combobox.ComboBox', {
                context: this.getContext().clone({
                    appID: null
                }),
                displayField: 'name',
                editable: false,
                listeners: {
                    change: this._onTimeboxTypeChanged,
                    ready: {
                        fn: function (combo) {
                            deferred.resolve(combo.getValue());
                        },
                        single: true
                    },
                    scope: this
                },
                plugins: [{
                    ptype: 'rallypreferenceenabledcombobox',
                    preferenceName: 'timebox-combobox'
                }],
                queryMode: 'local',
                renderTo: Ext.query('#content .titlebar .dashboard-timebox-container')[0],
                storeType: 'Ext.data.Store',
                storeConfig: {
                    fields: ['name', 'type'],
                    data: [
                        { name: 'Iterations', type: 'iteration' },
                        { name: 'Releases', type: 'release' },
                        { name: 'Milestones', type: 'milestone' }
                    ]
                },
                valueField: 'type'
            });

            return deferred.promise;
        },

        _onTimeboxTypeChanged: function () {
            if (this.modelPicker) {
                this.changeModelType(this.modelPicker.getValue());
            }
        }
    });
})();
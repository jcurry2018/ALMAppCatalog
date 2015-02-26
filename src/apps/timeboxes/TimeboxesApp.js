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
            'Rally.ui.gridboard.GridBoardToggle'
        ],

        enableGridBoardToggle: true,

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

        getGridConfig: function () {
            return _.merge(this.callParent(arguments), {
                enableSummaryRow: false
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
            }, this._getTypeSpecificAddNewConfig());
        },

        getFilterControlConfig: function () {
            return _.merge(this.callParent(arguments), {
                blackListFields: ['GrossEstimateConversionRatio', 'Theme']
            });
        },

        getGridStoreConfig: function() {
            return _.merge(this.callParent(arguments), {
                sorters: [ {property: this._getStartDateFieldName(), direction: 'DESC'} ]
            });
        },

        _getTypeSpecificAddNewConfig: function () {
            if (this.selectedType === 'milestone') {
                return {
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
                };
            }

            var startDateFieldName = this._getStartDateFieldName();
            var endDateFieldName = this.selectedType === 'release' ? 'ReleaseDate' : 'EndDate';

            return {
                additionalFields: [
                    {
                        xtype: 'rallydatefield',
                        allowBlank: false,
                        emptyText: 'Select Start Date',
                        name: startDateFieldName,
                        paramName: 'startDate'
                    }, {
                        xtype: 'rallydatefield',
                        allowBlank: false,
                        emptyText: this.selectedType === 'release' ? 'Select Release Date' : 'Select End Date',
                        name: endDateFieldName,
                        paramName: 'endDate'
                    }
                ],
                ignoredRequiredFields: ['GrossEstimateConversionRatio', 'Name', 'Project', 'State', startDateFieldName, endDateFieldName],
                listeners: {
                    beforecreate: function(addNew, record) {
                        record.set('State', 'Planning');
                    }
                }
            };
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

            this.modelPicker = Ext.create('Rally.ui.combobox.PreferenceEnabledComboBox', {
                context: this.getContext().clone({
                    appID: null
                }),
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
                editable: false,
                preferenceName: 'timebox-combobox',
                displayField: 'name',
                valueField: 'type',
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
                }
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
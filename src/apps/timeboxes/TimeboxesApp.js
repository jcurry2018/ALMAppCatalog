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
            'Rally.data.Ranker',
            'Rally.apps.timeboxes.IterationVelocityA0Chart',
            'Rally.data.PreferenceManager',
            'Rally.ui.combobox.plugin.PreferenceEnabledComboBox',
            'Rally.ui.gridboard.plugin.GridBoardInlineFilterControl',
            'Rally.ui.gridboard.GridBoardToggle',
            'Rally.ui.gridboard.plugin.GridBoardSharedViewControl',
            'Rally.ui.notify.Notifier'
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
                        if(this._isNewestFilteringComponentEnabled()){
                            this.loadSettingsAndLaunch();
                        }
                    },
                    scope: this
                });
            }
        },

        _isNewestFilteringComponentEnabled: function(){
            return this.getContext().isFeatureEnabled('S108174_UPGRADE_TO_NEWEST_FILTERING_SHARED_VIEWS_ON_TIMEBOXES');
        },

        _getAppId: function(newType){
            return this._isNewestFilteringComponentEnabled() ? -200034 : appIDMap[newType];
        },

        changeModelType: function (newType) {
            this.context = this.getContext().clone({
                appID: this._getAppId(newType)
            });
            this.selectedType = newType;
            this.modelNames = [newType];
            this.statePrefix = newType;
            if(!this._isNewestFilteringComponentEnabled()){
                this.loadSettingsAndLaunch();
            }
        },

        getGridBoardConfig: function () {
            return _.merge(this.callParent(arguments), {
                listeners: {
                    viewchange: this._onViewChange,
                    scope: this
                },
                sharedViewAdditionalCmps: [this.modelPicker]
            });
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

        getGridBoardCustomFilterControlConfig: function () {
            var context = this.getContext();
            if (this._isNewestFilteringComponentEnabled()) {
                return {
                    ptype: 'rallygridboardinlinefiltercontrol',
                    showInChartMode: false,
                    inlineFilterButtonConfig: {
                        stateful: true,
                        stateId: context.getScopedStateId('timeboxes-inline-filter'),
                        filterChildren: true,
                        modelNames: this.modelNames,
                        inlineFilterPanelConfig: {
                            quickFilterPanelConfig: {
                                defaultFields: [
                                    'ArtifactSearch'
                                ],
                                addQuickFilterConfig: {
                                    blackListFields: ['PortfolioItemType', 'ModelType', 'ChildrenPlannedVelocity'],
                                    whiteListFields: ['Milestones', 'Tags']
                                }
                            },
                            advancedFilterPanelConfig: {
                                advancedFilterRowsConfig: {
                                    propertyFieldConfig: {
                                        blackListFields: ['PortfolioItemType', 'ChildrenPlannedVelocity'],
                                        whiteListFields: ['Milestones', 'Tags']
                                    }
                                }
                            }
                        }
                    }
                };
            }

            return {
                blackListFields: ['PortfolioItemType'],
                whiteListFields: ['Milestones']
            };
        },

        getSharedViewConfig: function() {
            var context = this.getContext();
            if (this._isNewestFilteringComponentEnabled()) {
                return {
                    ptype: 'rallygridboardsharedviewcontrol',
                    showInChartMode: false,
                    sharedViewConfig: {
                        stateful: true,
                        stateId: context.getScopedStateId('timeboxes-shared-view'),
                        defaultViews: _.map(this._getDefaultViews(), function (view) {
                            Ext.apply(view, {
                                Value: Ext.JSON.encode(view.Value, true)
                            });
                            return view;
                        }, this),
                        enableUrlSharing: this.isFullPageApp !== false,
                        suppressViewNotFoundNotification: this._suppressViewNotFoundNotification
                    },
                    additionalFilters: [{
                        property: 'Value',
                        operator: 'contains',
                        value: '"timeboxTypePicker":"' + this.modelPicker.getRecord().get('type') + '"'
                    }]
                };
            }

            return {};
        },

        _getDefaultViews: function() {
            var defaultViews = [];
            if (this.toggleState === 'grid'){
                var modelType = this.modelPicker.getValue();
                if (modelType === 'iteration') {
                    defaultViews.push( {
                        Name: 'Iterations Default',
                        identifier: 1,
                        Value: {
                            toggleState: 'grid',
                            columns: [
                                {dataIndex: "Name"},
                                {dataIndex: "Theme"},
                                {dataIndex: "StartDate"},
                                {dataIndex: "EndDate"},
                                {dataIndex: "Project"},
                                {dataIndex: "PlannedVelocity"},
                                {dataIndex: "PlanEstimate"},
                                {dataIndex: "TaskEstimateTotal"},
                                {dataIndex: "TaskRemainingTotal"},
                                {dataIndex: "TaskActualTotal"},
                                {dataIndex: "State"}
                            ],
                            sorters:[{ property: 'EndDate', direction: 'DESC'}]
                        }
                    });
                } else if (modelType === 'milestone'){
                    defaultViews.push( {
                        Name: 'Milestones Default',
                        identifier: 2,
                        Value: {
                            toggleState: 'grid',
                            columns: [
                                {dataIndex: "FormattedID"},
                                {dataIndex: "DisplayColor"},
                                {dataIndex: "Name"},
                                {dataIndex: "TargetDate"},
                                {dataIndex: "TotalArtifactCount"},
                                {dataIndex: "TargetProject"}
                            ],
                            sorters:[{ property: 'TargetDate', direction: 'DESC'}]
                        }
                    });
                } else if (modelType === 'release'){
                    defaultViews.push( {
                        Name: 'Releases Default',
                        identifier: 3,
                        Value: {
                            toggleState: 'grid',
                            columns: [
                                {dataIndex: "Name"},
                                {dataIndex: "Theme"},
                                {dataIndex: "ReleaseStartDate"},
                                {dataIndex: "ReleaseDate"},
                                {dataIndex: "Project"},
                                {dataIndex: "PlannedVelocity"},
                                {dataIndex: "PlanEstimate"},
                                {dataIndex: "TaskEstimateTotal"},
                                {dataIndex: "TaskRemainingTotal"},
                                {dataIndex: "TaskActualTotal"},
                                {dataIndex: "State"}
                            ],
                            sorters:[{ property: 'ReleaseDate', direction: 'DESC'}]
                        }
                    });
                }
            }
            return defaultViews;
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
                store: {
                    fields: ['name', 'type', 'TypePath'],
                    data: [
                        { name: 'Iterations', type: 'iteration', TypePath: 'Iteration'},
                        { name: 'Releases', type: 'release', TypePath: 'Release' },
                        { name: 'Milestones', type: 'milestone', TypePath: 'Milestone' }
                    ]
                },
                valueField: 'type',
                getCurrentView: function () {
                    return {timeboxTypePicker: this.getRecord().get('type')};
                }
            });

            return deferred.promise;
        },

        _suppressViewNotFoundNotificationWhenTypeChanges: function() {
            var plugin = _.find(this.gridboard.plugins, {ptype: 'rallygridboardsharedviewcontrol'});
            if (plugin && plugin.controlCmp && plugin.controlCmp.getSharedViewParam()){
                this._suppressViewNotFoundNotification = true;
            }
        },

        _onViewChange: function() {
            Rally.ui.notify.Notifier.hide();
            this.loadGridBoard();
        },

        _pickerTypeChanged: function(picker){
            var newType = picker.getValue();
            return newType && this.selectedType && newType !== this.selectedType;
        },

        _onTimeboxTypeChanged: function (picker) {
            Rally.ui.notify.Notifier.hide();
            if (this._pickerTypeChanged(picker)) {
                this._suppressViewNotFoundNotificationWhenTypeChanges();
                this.changeModelType(picker.getValue());

                if(this._isNewestFilteringComponentEnabled()){
                    var selectedRecord = this.modelPicker.getRecord();

                    if (!this._enableCharts()) {
                        this.toggleState = 'grid';
                    }

                    this.gridboard.fireEvent('modeltypeschange', this.gridboard, [selectedRecord]);
                }
            }
        },

        onDestroy: function() {
            this.callParent(arguments);
            if(this.modelPicker) {
                this.modelPicker.destroy();
                delete this.modelPicker;
            }
        }
    });
})();
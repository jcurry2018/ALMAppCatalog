(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.milestones.MilestonesApp', {
        extend: 'Rally.apps.common.GridBoardApp',
        requires: [
            'Rally.ui.DateField',
            'Rally.ui.combobox.MilestoneProjectComboBox',
            'Rally.ui.grid.MilestoneProjectEditor'
        ],
        cls: 'milestones-app',
        config: {
            enableOwnerFilter: false,
            modelNames: ['Milestone'],
            defaultSettings: {
                columnNames: ['FormattedID','DisplayColor','Name','TargetDate','TotalArtifactCount','TargetProject']
            }
        },

        getStateId: function () {
            return 'milestone';
        },

        getGridConfig: function () {
            return _.merge(this.callParent(arguments), {
                enableRanking: false,
                noDataItemName: 'milestone',
                rowActionColumnConfig: {
                    rowActionsFn: function (record) {
                        return Rally.ui.grid.MilestoneProjectEditor.shouldDisableEditing(record.get('TargetProject')) ? [] : [
                            {
                                xtype: 'rallyrecordmenuitemdelete',
                                record: record
                            }
                        ];
                    }
                },
                storeConfig: {
                    filters: [
                        Rally.data.wsapi.Filter.or([
                            {property: 'Projects', operator: 'contains', value: this.getContext().getProjectRef()},
                            {property: 'TargetProject', operator: '=', value: null}
                        ])
                    ]
                }
            });
        },

        getColumnCfgs: function () {
            var columnCfgs = this.callParent(arguments);

            // When this toggle is removed, RendererFactory.js should be updated to render milestone formatted ids
            // as links and this function can go away.
            if (this.getContext().isFeatureEnabled('EDP_MILESTONE_BETA')) {
                var formattedIDIndex = _.indexOf(columnCfgs, "FormattedID");
                if (formattedIDIndex !== -1) {
                    columnCfgs[formattedIDIndex] = {
                        dataIndex: 'FormattedID',
                        renderer: function (formattedID, obj, record) {
                            return Ext.create('Rally.ui.renderer.template.FormattedIDTemplate').apply({
                                _type: 'milestone',
                                _ref: record.get('_ref'),
                                FormattedID: formattedID,
                                DisplayColor: record.get('DisplayColor')
                            });
                        }
                    };
                }
            }
            return columnCfgs;
        },
        
        getAdditionalFetchFields: function () {
            return ['DisplayColor'];
        },

        getGridStoreConfig: function () {
            return {
                enableHierarchy: false,
                childPageSizeEnabled: false
            };
        },

        getFieldPickerConfig: function () {
            var config = this.callParent(arguments);
            config.gridFieldBlackList = _.union(config.gridFieldBlackList, [
                'Artifacts',
                'CreationDate',
                'Projects',
                'VersionId'
            ]);
            return _.merge(config, {
                gridAlwaysSelectedValues: ['FormattedID', 'Name', 'TargetDate', 'TotalArtifactCount', 'TargetProject']
            });
        },

        getAddNewConfig: function () {
            return {
                showRank: false,
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
            };
        }
    });
})();
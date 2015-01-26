(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.PlanningBoard', {
        extend: 'Rally.ui.cardboard.CardBoard',
        alias: 'widget.roadmapplanningboard',

        requires: [
            'Rally.data.util.PortfolioItemHelper',
            'Rally.apps.roadmapplanningboard.PlanningBoardColumn',
            'Rally.apps.roadmapplanningboard.TimeframePlanningColumn',
            'Rally.apps.roadmapplanningboard.BacklogBoardColumn',
            'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper',
            'Rally.apps.roadmapplanningboard.util.PlanGenerator',
            'Rally.ui.Button',
            'Rally.ui.grid.TreeGrid',
            'Rally.data.PreferenceManager'
        ],

        cls: 'roadmap-board cardboard',

        statics: {
            PREFERENCE_NAME: 'roadmapplanningboard.header.expanded'
        },

        config: {
            roadmap: null,
            timeline: null,
            isAdmin: false,
            showHeader: true,
            storeConfig: {
                useShallowFetch: true,
                enablePostGet: true
            },
            cardConfig: {
                editable: true,
                skipDefaultFields: true,
                customFieldConfig: {
                    UserStories: {
                        popoverConfig: {
                            placement: ['bottom', 'right', 'left', 'top'],
                            listViewConfig: {
                                addNewConfig: {
                                    showAddWithDetails: false
                                },
                                gridConfig: {
                                    columnCfgs: [
                                        'FormattedID',
                                        'Name',
                                        {
                                            dataIndex: 'ScheduleState', // 'dataIndex' is the actual field name
                                            text: 'State' // 'text' is the display name
                                        },
                                        {
                                            dataIndex: 'PlanEstimate',
                                            editor: {
                                                decimalPrecision: 0
                                            }
                                        },
                                        'Project'
                                    ]
                                }
                            }
                        }
                    }
                }
            },
            columnConfig: {
                additionalFetchFields: ['PreliminaryEstimate', 'RefinedEstimate']
            },
            ddGroup: 'planningBoard',
            dropAllowed: "planningBoard",
            dropNotAllowed: "planningBoard",

            /**
             * @cfg {Object} Object containing Names and TypePaths of the lowest level portfolio item (eg: 'Feature') and optionally its parent (eg: 'Initiative')
             */
            typeNames: {}
        },

        initComponent: function () {
            this.timeframePlanStoreWrapper = Ext.create('Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper', {
                requester: this,
                roadmap: this.roadmap,
                timeline: this.timeline
            });

            if(!this.typeNames.child || !this.typeNames.child.name) {
                throw 'typeNames must have a child property with a name';
            }

            this.mergeConfig(this.config);

            this.callParent(arguments);
        },

        refresh: function (options) {
            options = options || {};

            if (options.rebuildBoard) {
                this.showMask('Refreshing the board...');
                this.addCls('loading');

                return this._loadColumnData().then({
                    success: function () {
                        var firstTimeframeColumn = this.getColumns()[1]; // first visible timeframe column
                        var firstTimeframeRecord = firstTimeframeColumn && firstTimeframeColumn.timeframeRecord;

                        this.buildColumns({
                            firstTimeframe: firstTimeframeRecord,
                            render: true
                        });
                    },
                    scope: this
                }).then({
                    success: this._refreshBacklog,
                    scope: this
                }).always(function () {
                    this.hideMask();
                    this.removeCls('loading');
                }, this);
            } else {
                var deferred = new Deft.Deferred();
                this.on('load', function () { deferred.resolve(); }, this, {single: true});

                this.callParent(arguments);

                return deferred.promise;
            }
        },

        shouldRetrieveModels: function () {
            return !this.columns || this.columns.length === 0;
        },

        onModelsRetrieved: function (callback) {
            return this._loadColumnData().then({
                success: function () {
                    this.buildColumns();
                    callback.call(this);
                },
                scope: this
            });
        },

        _loadColumnData: function () {
            return this.timeframePlanStoreWrapper.load().then({
                failure: function (operation) {
                    var service = operation.storeServiceName || 'External';
                    Rally.ui.notify.Notifier.showError({message: 'Failed to load: ' + service + ' service data load issue'});
                },
                scope: this
            });
        },

        drawAddNewColumnButton: function () {
            var column = this.getRightmostColumn();
            if (column.rendered && this.isAdmin) {
                if (this.addNewColumnButton) {
                    this.addNewColumnButton.destroy();
                }
                this.addNewColumnButton = Ext.create('Rally.ui.Button', {
                    border: 1,
                    text: '<i class="icon-add"></i>',
                    elTooltip: 'Add Timeframe',
                    cls: 'scroll-button rly-right',
                    height: 28,
                    frame: false,
                    handler: this._addNewColumn,
                    renderTo: column.getHeaderTitle().getEl(),
                    scope: this,
                    userAction: 'rpb add timeframe'
                });
            }
        },

        getRightmostColumn: function () {
            return _.last(this.getColumns());
        },

        /**
         * @inheritDoc
         */
        renderColumns: function () {
            this.callParent(arguments);

            if(this.firstLoad) {
                var titleField = this.getColumns()[1].columnHeader.down('rallyclicktoeditfieldcontainer');
                if(titleField) {
                    titleField.goToEditMode();
                }

                this.firstLoad = false;
            }

            this.drawAddNewColumnButton();
        },

        /**
         * This method will build an array of columns from timeframe and plan stores
         * @returns {Array} columns
         */
        buildColumns: function () {
            var planColumns = _.map(this.timeframePlanStoreWrapper.getTimeframeAndPlanRecords(), function (record) {
                return this._addColumnFromTimeframeAndPlan(record.timeframe, record.plan);
            }, this);

            this.columns = [this._getBacklogColumnConfig()].concat(planColumns);

            return this.columns;
        },

        _getBacklogColumnConfig: function () {
            return {
                xtype: 'backlogplanningcolumn',
                types: this.types,
                typeNames: this.typeNames,
                planStore: this.timeframePlanStoreWrapper.planStore,
                enableCrossColumnRanking: false,
                cls: 'column backlog'
            };
        },

        /**
         * Return the backlog column if it exists
         * @returns {Rally.apps.roadmapplanningboard.BacklogBoardColumn} column The backlog column of the cardboard
         */
        getBacklogColumn: function () {
            var columns = this.getColumns();

            if (!Ext.isEmpty(columns)) {
                return columns[0];
            } else {
                return null;
            }
        },

        /**
         * Get the first record of the cardboard
         * @returns {Rally.data.Record}
         */
        getFirstRecord: function () {
            var cards;
            var record = null;
            var column = this.getBacklogColumn();

            if (column) {
                cards = column.getCards();
                if (!Ext.isEmpty(cards)) {
                    record = cards[0].getRecord();
                }
            }
            return record;
        },

        _addNewColumn: function (options) {
            options = options || {};

            this.addNewColumnButton.setDisabled(true);

            var getRecordPromise;

            if (options.timeframeRecord && options.planRecord) {
                var deferred = new Deft.Deferred();
                deferred.resolve({
                    timeframeRecord: options.timeframeRecord,
                    planRecord: options.planRecord
                });
                getRecordPromise = deferred.promise;
            } else {
                getRecordPromise = this._addNewPlanRecord();
            }

            return getRecordPromise.then({
                success: function (records) {
                    var column = this.addNewColumn(this._addColumnFromTimeframeAndPlan(records.timeframeRecord, records.planRecord));
                    column.columnHeader.down('rallyclicktoeditfieldcontainer').goToEditMode();
                    return column;
                },
                failure: function (error) {
                    this.addNewColumnButton.setDisabled(false);
                    Rally.ui.notify.Notifier.showError({message: 'Failed to create new column: ' + error});
                },
                scope: this
            });
        },

        _addNewPlanRecord: function (options) {
            var generator = Ext.create('Rally.apps.roadmapplanningboard.util.PlanGenerator', {
                timeframePlanStoreWrapper: this.timeframePlanStoreWrapper,
                roadmap: this.roadmap
            });

            return generator.createPlanWithTimeframe(options);
        },

        addNewColumn: function (columnConfig) {
            var columnEls = this.createColumnElements('after', _.last(this.getColumns()));
            var column = this.addColumn(columnConfig, this.getColumns().length);
            this.renderColumn(column, columnEls);

            this.drawAddNewColumnButton();

            return column;
        },

        _addColumnFromTimeframeAndPlan: function (timeframe, plan) {
            return {
                xtype: 'timeframeplanningcolumn',
                timeframeRecord: timeframe,
                planRecord: plan,
                timeframePlanStoreWrapper: this.timeframePlanStoreWrapper,
                types: this.types,
                typeNames: this.typeNames,
                columnHeaderConfig: {
                    record: timeframe,
                    fieldToDisplay: 'name',
                    editable: this.isAdmin
                },
                editPermissions: {
                    capacityRanges: this.isAdmin,
                    theme: this.isAdmin,
                    timeframeDates: this.isAdmin,
                    deletePlan: this.isAdmin
                },
                enableCrossColumnRanking: true,
                dropControllerConfig: {
                    dragDropEnabled: this.isAdmin
                },
                isMatchingRecord: function (featureRecord) {
                    return plan && _.find(plan.get('features'), function (feature) {
                        return (feature.id === featureRecord.get('_refObjectUUID'));
                    });
                },
                listeners: {
                    deleteplan: this._deleteTimeframePlanningColumn,
                    daterangechange: this._onColumnDateRangeChange,
                    scope: this
                }
            };
        },

        _onColumnDateRangeChange: function (column) {
            // resorting of columns handled in RoadmapScrollable plugin
        },

        _deleteTimeframePlanningColumn: function (column) {
            this.pendingDeletions = this.pendingDeletions || [];
            this.pendingDeletions.push(column.planRecord);

            var deletingLastColumn = (this.timeframePlanStoreWrapper.planStore.count() - this.pendingDeletions.length) < 1;

            if (column.deletePlanButton) {
                column.deletePlanButton.hide();
            }

            if (deletingLastColumn) {
                return this._addNewPlanRecord({resetDates: true}).then({
                    success: function (options) {
                        this._deletePlan(column).then({
                            success: function () {
                                this._addNewColumn(options);
                            },
                            scope: this
                        });
                    },
                    scope: this
                });
            }

            return this._deletePlan(column);
        },

        _deletePlan: function (column) {
            var timeframeName = column.timeframeRecord.get('name');
            var planRecordToDelete = column.planRecord;
            var columnHadFeatures = column.planRecord.get('features').length;

            return this.timeframePlanStoreWrapper.deletePlan(column.planRecord).then({
                success: function () {
                    this.destroyColumn(column);
                    this.pendingDeletions = _.reject(this.pendingDeletions, function (record) {
                        return record.getId() === planRecordToDelete.getId();
                    });
                    if (columnHadFeatures) {
                        this._refreshBacklog();
                    }
                    Rally.ui.notify.Notifier.showConfirmation({message: 'Column "' + timeframeName + '" deleted.'});
                },
                failure: function (error) {
                    Rally.ui.notify.Notifier.showError({message: error});
                },
                scope: this
            });
        },

        _isColumnOutOfOrder: function (currentColumn) {
            var columns = this.getColumns();
            var currentColumnIndex = _.findIndex(columns, function (column) {
                return column.getId() === currentColumn.getId();
            }, this);

            var previousColumn = columns[currentColumnIndex - 1] || null;
            var nextColumn = columns[currentColumnIndex + 1] || null;

            var previousTimeframe = previousColumn && previousColumn.timeframeRecord;
            var nextTimeframe = nextColumn && nextColumn.timeframeRecord;

            var startsAfterPreviousTimeframe = !previousTimeframe || (currentColumn.timeframeRecord.get('endDate') > previousTimeframe.get('endDate'));
            var endsBeforeNextTimeframe = !nextTimeframe || (currentColumn.timeframeRecord.get('endDate') < nextTimeframe.get('endDate'));

            return !startsAfterPreviousTimeframe || !endsBeforeNextTimeframe;
        },

        _refreshBacklog: function () {
            this.getColumns()[0].refresh();
        }

    });

})();

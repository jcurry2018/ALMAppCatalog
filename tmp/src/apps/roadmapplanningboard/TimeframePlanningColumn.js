(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.TimeframePlanningColumn', {
        extend: 'Rally.apps.roadmapplanningboard.PlanningBoardColumn',
        alias: 'widget.timeframeplanningcolumn',

        requires: [
            'Rally.data.wsapi.filter.MultiSelectFilter',
            'Rally.apps.roadmapplanningboard.ThemeHeader',
            'Rally.apps.roadmapplanningboard.PlanCapacityProgressBar',
            'Rally.apps.roadmapplanningboard.util.Fraction',
            'Rally.apps.roadmapplanningboard.PlanningCapacityPopoverView',
            'Rally.apps.roadmapplanningboard.util.TimelineViewModel'
        ],

        mixins: [ 'Rally.apps.roadmapplanningboard.mixin.CollapsableHeaderContainer' ],

        config: {
            startDateField: 'startDate',
            endDateField: 'endDate',
            editPermissions: {
                capacityRanges: true,
                theme: true,
                timeframeDates: true,
                deletePlan: true
            },
            timeframePlanStoreWrapper: undefined,
            timeframeRecord: undefined,
            planRecord: undefined,
            dateFormat: 'M j',
            pointFields: ['RefinedEstimate', 'PreliminaryEstimate']
        },

        constructor: function (config) {
            this.mergeConfig(config);
            this.config.storeConfig = this.config.storeConfig || {};
            this.config.storeConfig.sorters = [
                {
                    sorterFn: Ext.bind(this._sortPlan, this)
                }
            ];
            this.config.storeConfig.pageSize = 200;
            this.callParent([this.config]);
        },

        initComponent: function () {
            this.callParent(arguments);

            this.addEvents('deleteplan', 'daterangechange');

            this.mon(this, 'ready', this._updateHeader, this);
            this.mon(this, 'addcard', this._updateHeader, this);
            this.mon(this, 'cardupdated', this._updateHeader, this);
            this.mon(this, 'removecard', this._updateHeader, this);

            if (this.planRecord && this.planRecord.store) {
                this.planRecord.store.on('update', function () {
                    this._updateHeader();
                }, this);
            }
            this._createDummyPlannedCapacityRangeTooltipForSizeCalculations();
        },

        _createDummyPlannedCapacityRangeTooltipForSizeCalculations: function () {
            this.dummyPlannedCapacityRangeTooltip = Ext.create('Rally.ui.tooltip.ToolTip', {
                target: Ext.getBody(),
                html: this._getPlannedCapacityRangeTooltipTitle(),
                listeners: {
                    beforeshow: function () {
                        this.hide();
                    }
                }
            });
            this.dummyPlannedCapacityRangeTooltip.show();
        },

        getColumnIdentifier: function () {
            return "planningboardtimeframecolumn" + this.planRecord.getId();
        },

        /**
         * @private
         * Custom sort function for the plan column. It uses the order of features within the plan record to determine
         * the order of feature cards. WSAPI gives us the features in a different order than we want, so we must
         * reorder
         * @param a {Rally.data.Model} The first record to compare
         * @param b {Rally.data.Model} The second record to compare
         * @returns {Number}
         */
        _sortPlan: function (a, b) {
            var aIndex = this._findFeatureIndex(a);
            var bIndex = this._findFeatureIndex(b);

            return aIndex > bIndex ? 1 : -1;
        },

        /**
         * @private
         * Return the index of the feature in the plan record. This is used to sort records returned from WSAPI
         * @param {Rally.data.Model} record
         * @returns {Number} This will return the index of the record in the plan features array
         */
        _findFeatureIndex: function (record) {
            return _.findIndex(this.planRecord.get('features'), function (feature) {
                return feature.id === record.get('_refObjectUUID').toString();
            });
        },

        /**
         * Override
         * @returns {boolean}
         */
        mayRank: function () {
            return this._getSortDirection() === 'ASC' && this.enableRanking;
        },

        afterRender: function (event) {
            this.callParent(arguments);
            if (this.editPermissions.capacityRanges) {
                this.columnHeader.getEl().on('click', this.onProgressBarClick, this, {
                    delegate: '.progress-bar-container'
                });
            }
            if (this.editPermissions.timeframeDates) {
                this.columnHeader.getEl().on('click', this.onTimeframeDatesClick, this, {
                    delegate: '.timeframeDates'
                });
            }
        },

        loadStore: function () {
            this._updatePlanFeatureFilter();
            this.callParent(arguments);
        },

        filter: function () {
            this._updatePlanFeatureFilter();
            this.callParent(arguments);
        },

        _updatePlanFeatureFilter: function () {
            if (this.filterCollection) {
                this.filterCollection.removeTempFilterByKey('planfeatures');
                this.filterCollection.addTempFilter(this._createFeatureFilter());
            }
        },

        getStoreFilter: function () {
            return null;
        },

        _createFeatureFilter: function () {
            var features = this.planRecord.data.features.length > 0 ? this.planRecord.data.features : [null];
            return Ext.create('Rally.data.wsapi.filter.MultiSelectFilter', {
                itemId: 'planfeatures',
                filterProperty: 'ObjectID',
                operator: '=',
                value: features,
                getFilterValue: function (feature) { return feature && feature.id; }
            });
        },

        addCapacityClick: function(button, event) {
            this.onProgressBarClick(event);
        },

        onProgressBarClick: function (event) {
            var target = Ext.get(Ext.query('.progress-bar-background', this.getColumnHeader().getEl().dom)[0]);

            event.stopPropagation();
            this.plannedCapacityRangeTooltip.disable();

            if (this.popover) {
                return;
            }
            this.popover = Ext.create('Rally.apps.roadmapplanningboard.PlanningCapacityPopoverView', {
                target: target,
                owner: this,
                offsetFromTarget: [
                    { x: 0, y: 0 },
                    { x: 0, y: 0 },
                    { x: 0, y: 5 },
                    { x: 0, y: 0 }
                ],
                model: this.planRecord,
                listeners: {
                    destroy: function () {
                        this.popover = null;
                        if (this._getHighCapacity()) {
                            this.plannedCapacityRangeTooltip.enable();
                        }
                    },
                    scope: this
                }
            });
        },

        onTimeframeDatesClick: function (event) {
            var _this = this;

            this.timeframePopover = Ext.create('Rally.apps.roadmapplanningboard.TimeframeDatesPopoverView', {
                target: Ext.get(event.target),
                offsetFromTarget: [
                    { x: 0, y: 0 },
                    { x: 0, y: 0 },
                    { x: 0, y: 5 },
                    { x: 0, y: 0 }
                ],
                timelineViewModel: Rally.apps.roadmapplanningboard.util.TimelineViewModel.createFromStores(this.timeframePlanStoreWrapper, this.timeframeRecord),
                listeners: {
                    destroy: function () {
                        _this._drawDateRange();
                        _this.timeframePopover = null;
                    },
                    save: function (options) {
                        _this._saveTimeframeDates(options);
                    }
                }
            });
        },

        _drawCollapsableContainer: function() {
            if (!this.collapsableContainer) {
                this.collapsableContainer = this.getColumnHeader().add(this._getCollapsableHeaderContainerConfig());
            }
        },

        _drawDateRange: function () {
            if (this.dateRange) {
                this.dateRange.update(this.getDateHeaderTplData());
            } else {
                this.dateRange = this.collapsableContainer.add({
                    xtype: 'component',
                    cls: 'timeframeDatesContainer',
                    tpl: "<div class='timeframeDates {clickableClass}'>{formattedDate}</div>",
                    data: this.getDateHeaderTplData(),
                    listeners: {
                        afterrender: this._createDateRangeTooltip,
                        scope: this
                    }
                });
            }
        },

        _createDateRangeTooltip: function () {
            if (this.editPermissions.timeframeDates) {
                if (this.dateRangeTooltip) {
                    this.dateRangeTooltip.destroy();
                }

                this.dateRangeTooltip = Ext.create('Rally.ui.tooltip.ToolTip', {
                    target: this.dateRange.getEl(),
                    hideDelay: 100,
                    anchor: 'right',
                    html: this.getDateHeaderTplData().titleText
                });
            }
        },

        _drawProgressBar: function () {
            if (this.progressBar) {
                this.progressBar.update(this.getHeaderTplData());
                this._afterProgressBarRender();
            } else {
                this.progressBar = this.collapsableContainer.add({
                    xtype: 'container',
                    tpl: [
                        '<div class="progress-bar-background">',
                        '<tpl if="highCapacity">',
                        '<div class="progress-bar-percent-done">{formattedPercent}</div>',
                        '<div class="progress-bar-display">{progressBarHtml}</div>',
                        '<tpl else>',
                        '<div>',
                        '<span>{pointTotal}</span> <span class="no-capacity-label">{itemType} {pointText}</span>',
                        '<div class="add-capacity"></div>',
                        '</div>',
                        '</tpl>',
                        '</div>'
                    ],
                    data: this.getHeaderTplData(),
                    listeners: {
                        afterrender: this._afterProgressBarRender,
                        scope: this
                    }
                });
            }
        },

        _afterProgressBarRender: function () {
            this._addCapacityButton();
            this._createPlannedCapacityRangeTooltip();
            if (this._getHighCapacity()) {
                this.plannedCapacityRangeTooltip.enable();
            } else {
                this.plannedCapacityRangeTooltip.disable();
            }
        },

        _addCapacityButton: function () {
            if (this.editPermissions.capacityRanges && this.rendered) {
                Ext.create('Rally.ui.Button', {
                    text: 'Set Capacity',
                    cls: 'secondary dark',
                    renderTo: Ext.query('.add-capacity', this.getColumnHeader().getEl().dom)[0],
                    handler: this.addCapacityClick,
                    scope: this
                });
            }
        },

        _createPlannedCapacityRangeTooltip: function () {
            if (this.plannedCapacityRangeTooltip) {
                return;
            }

            var anchorOffset = 0;
            var mouseXOffset = 0;

            if (this.dummyPlannedCapacityRangeTooltip) {
                var tooltipWidth = this.dummyPlannedCapacityRangeTooltip.getWidth();
                var anchorWidth = this.dummyPlannedCapacityRangeTooltip.getEl().down('.' + Ext.baseCSSPrefix + 'tip-anchor').getWidth();
                anchorOffset = tooltipWidth / 2 - anchorWidth;
                var width = this.rendered ? this.getWidth() : 0;
                mouseXOffset = (width - tooltipWidth) / 2;
                this.dummyPlannedCapacityRangeTooltip.destroy();
            }

            this.plannedCapacityRangeTooltip = Ext.create('Rally.ui.tooltip.ToolTip', {
                cls: 'planned-capacity-range-tooltip',
                target: this.progressBar.getEl(),
                constrainPosition: false,
                anchor: 'top',
                anchorOffset: anchorOffset,
                mouseOffset: [ mouseXOffset, 0],
                hideDelay: 100,
                html: this._getPlannedCapacityRangeTooltipTitle()
            });
        },

        _drawTheme: function () {
            if (!this.theme && this.planRecord) {
                this.theme = this.collapsableContainer.add({
                    xtype: 'roadmapthemeheader',
                    record: this.planRecord,
                    editable: this.editPermissions.theme
                });
            }
        },

        _drawHeaderButtons: function () {
            if (!this.headerButtonContainer) {
                this.headerButtonContainer = this.getHeaderTitle().add({
                    xtype: 'container',
                    cls: 'header-button-container'
                });
            }

            this._drawDeletePlanButton();
        },

        _drawDeletePlanButton: function () {
            if (!this.deletePlanButton && this.editPermissions.deletePlan) {
                this.deletePlanButton = this.headerButtonContainer.add({
                    xtype: 'rallybutton',
                    iconCls: 'icon-delete',
                    cls: 'picto small',
                    elTooltip: 'Delete column',
                    listeners: {
                        click: function () {
                            if (this.planRecord.get('features').length ) {
                                this._drawDeletePlanConfirmDialog();
                            } else {
                                this.fireEvent('deleteplan', this);
                            }
                        },
                        scope: this
                    }
                });
            }
        },

        _drawDeletePlanConfirmDialog: function () {
            if (this.confirmationDialog) {
                this.confirmationDialog.destroy();
            }

            this.confirmationDialog = Ext.create('Rally.ui.dialog.ConfirmDialog', {
                cls: 'roadmap-delete-plan-confirm',
                title: '<span class="title-icon icon-warning"></span>Delete Plan from Roadmap',
                message: 'Deleting this plan will remove the timeframe for all projects and return features in this plan to the backlog.',
                confirmLabel: 'Delete',
                listeners: {
                    confirm: function () {
                        this.fireEvent('deleteplan', this);
                    },
                    scope: this
                }
            });
        },

        destroy: function () {
            if (this.confirmationDialog) {
                this.confirmationDialog.destroy();
            }
            this.callParent(arguments);
        },

        getHeaderTplData: function () {
            var pointFields = this.pointFields;
            var highCapacity = this._getHighCapacity();
            var lowCapacity = (this.planRecord && this.planRecord.get('lowCapacity')) || 0;

            var fraction = Ext.create('Rally.apps.roadmapplanningboard.util.Fraction', {
                denominator: highCapacity,
                numeratorItems: this.getCards(true),
                numeratorItemValueFunction: function (card) {
                    var value = _.find(_.map(pointFields, function(pointField) {
                        var fieldValue = card.getRecord().get(pointField);
                        return fieldValue ? (fieldValue.Value || fieldValue) : false;
                    }));

                    return value || 0;
                }
            });

            var pointTotal = fraction.getNumerator();

            return {
                highCapacity: highCapacity,
                lowCapacity: lowCapacity,
                pointTotal: pointTotal,
                pointText: 'pt' + (pointTotal !== 1 ? 's' : ''),
                itemType: this.typeNames.child.name.toLowerCase(),
                progressBarHtml: this._getProgressBarHtml(fraction),
                formattedPercent: fraction.getFormattedPercent(),
                progressBarTitle: this._getPlannedCapacityRangeTooltipTitle()
            };
        },

        _getHighCapacity: function () {
            return (this.planRecord && this.planRecord.get('highCapacity')) || 0;
        },

        getDateHeaderTplData: function () {
            return {
                formattedDate: this._getDateRange(),
                titleText: 'Edit Date Range',
                clickableClass: this.editPermissions.timeframeDates ? 'clickable' : ''
            };
        },

        drawHeader: function () {
            this.callParent(arguments);
            this._updateHeader();
        },

        _updateHeader: function () {
            if (!this.destroying && this.rendered) {
                this._drawCollapsableContainer();
                this._drawDateRange();
                this._drawProgressBar();
                this._drawTheme();
                this._drawHeaderButtons();
            }
        },

        _getDateRange: function () {
            var formattedEndDate, formattedStartDate;

            formattedStartDate = this._getFormattedDate(this.startDateField);
            formattedEndDate = this._getFormattedDate(this.endDateField);
            if (!formattedStartDate && !formattedEndDate) {
                return "&nbsp;";
            }
            return "" + formattedStartDate + " - " + formattedEndDate;
        },

        _getFormattedDate: function (dateField) {
            var date;

            date = this.timeframeRecord.get(dateField);
            if (date) {
                return Ext.Date.format(date, this.dateFormat);
            }
        },

        _getProgressBarHtml: function (fraction) {
            var progressBar = Ext.create('Rally.apps.roadmapplanningboard.PlanCapacityProgressBar', {
                isClickable: this.editPermissions.capacityRanges
            });

            var lowCapacity = this.planRecord ? this.planRecord.get('lowCapacity') : undefined;
            var highCapacity = this.planRecord ? this.planRecord.get('highCapacity') : undefined;

            return progressBar.apply({
                low: lowCapacity || 0,
                high: highCapacity || 0,
                total: fraction.getNumerator(),
                percentDone: fraction.getPercent()
            });
        },

        _getPlannedCapacityRangeTooltipTitle: function () {
            var title = 'Planned Capacity Range';
            return this.editPermissions.capacityRanges ? 'Edit ' + title : title;
        },

        _saveTimeframeDates: function (options) {
            this.timeframeRecord.set('startDate', options.startDate);
            this.timeframeRecord.set('endDate', options.endDate);

            if (this.timeframeRecord.dirty) {
                this.timeframeRecord.save({
                    success: function () {
                        this.fireEvent('daterangechange', this);
                    },
                    requester: this.view,
                    scope: this
                });
            }

            return true;
        }
    });

})();

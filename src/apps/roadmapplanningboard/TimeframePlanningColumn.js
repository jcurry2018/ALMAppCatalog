(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.TimeframePlanningColumn', {
        extend: 'Rally.apps.roadmapplanningboard.PlanningBoardColumn',
        alias: 'widget.timeframeplanningcolumn',

        requires: [
            'Rally.data.QueryFilter',
            'Rally.apps.roadmapplanningboard.ThemeHeader',
            'Rally.apps.roadmapplanningboard.PlanCapacityProgressBar',
            'Rally.apps.roadmapplanningboard.util.Fraction',
            'Rally.apps.roadmapplanningboard.PlanningCapacityPopoverView'
        ],

        config: {
            startDateField: 'start',
            endDateField: 'end',
            editPermissions: {
                capacityRanges: true,
                theme: true,
                timeframeDates: true
            },
            timeframeRecord: undefined,
            planRecord: undefined,
            dateFormat: 'M j',
            headerTemplate: undefined,
            pointField: 'PreliminaryEstimate'
        },

        initComponent: function () {
            this.callParent(arguments);

            this.on('ready', this.drawHeader, this);
            this.on('addcard', this.drawHeader, this);
            this.on('cardupdated', this.drawHeader, this);
            this.on('removecard', this.drawHeader, this);
            this.on('afterrender', this.onAfterRender, this);

            if (this.planRecord && this.planRecord.store) {
                this.planRecord.store.on('update', function () {
                    this.drawHeader();
                }, this);
            }
        },

        onAfterRender: function (event) {
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

        getStoreFilter: function (model) {
            var result = _.reduce(this.planRecord.data.features, function (result, feature) {
                var filter = Ext.create('Rally.data.QueryFilter', {
                    property: 'ObjectID',
                    operator: '=',
                    value: feature.id
                });
                if (!result) {
                    return filter;
                } else {
                    return result.or(filter);
                }
            }, null);
            return result || [];
        },

        onProgressBarClick: function (event) {
            var _this = this;

            if (this.popover) {
                return;
            }
            this.popover = Ext.create('Rally.apps.roadmapplanningboard.PlanningCapacityPopoverView', {
                target: Ext.get(event.target),
                owner: this,
                offsetFromTarget: [
                    {
                        x: 0,
                        y: 0
                    },
                    {
                        x: 0,
                        y: 0
                    },
                    {
                        x: 0,
                        y: 16
                    },
                    {
                        x: 0,
                        y: 0
                    }
                ],
                controllerConfig: {
                    model: this.planRecord
                },
                listeners: {
                    beforedestroy: function () {
                        _this.popover = null;
                    }
                }
            });
        },

        onTimeframeDatesClick: function (event) {
            var _this = this;

            this.timeframePopover = Ext.create('Rally.apps.roadmapplanningboard.TimeframeDatesPopoverView', {
                target: Ext.get(event.target),
                offsetFromTarget: [
                    {
                        x: 0,
                        y: 0
                    },
                    {
                        x: 0,
                        y: 0
                    },
                    {
                        x: 0,
                        y: 5
                    },
                    {
                        x: 0,
                        y: 0
                    }
                ],
                controllerConfig: {
                    model: this.timeframeRecord
                },
                listeners: {
                    destroy: function () {
                        _this._drawDateRange();
                        _this.timeframePopover = null;
                    }
                }
            });
        },

        _drawDateRange: function () {
            if (this.dateRange) {
                this.dateRange.update(this.getDateHeaderTplData());
            } else {
                this.dateRange = this.getHeaderTitle().add({
                    xtype: 'component',
                    tpl: "<div class='timeframeDates {clickableClass}' title='{titleText}'>{formattedDate}</div>",
                    data: this.getDateHeaderTplData()
                });
            }
        },

        _drawProgressBar: function () {
            if (this.progressBar) {
                return this.progressBar.update(this.getHeaderTplData());
            } else {
                this.progressBar = this.getColumnHeader().add({
                    xtype: 'container',
                    tpl: "<div class='progress-bar-background'>\n    <div title='{progressBarTitle}'>{progressBarHtml}</div>\n    <div class='progress-bar-percent-done'>{formattedPercent}</div>\n</div>",
                    data: this.getHeaderTplData()
                });
            }
        },

        _drawTheme: function () {
            if (!this.theme && this.planRecord) {
                this.theme = this.getColumnHeader().add({
                    xtype: 'roadmapthemeheader',
                    record: this.planRecord,
                    editable: this.editPermissions.theme,
                    style: {
                        display: this.ownerCardboard.showTheme ? '' : 'none' // DE18305 - using style.display instead of hidden because Ext won't render children that are hidden
                    }
                });
            }
        },

        getHeaderTplData: function () {
            var fraction, _ref,
                _this = this;

            fraction = Ext.create('Rally.apps.roadmapplanningboard.util.Fraction', {
                denominator: ((_ref = this.planRecord) !== null ? _ref.get('highCapacity') : undefined) || 0,
                numeratorItems: this.getCards(true),
                numeratorItemValueFunction: function (card) {
                    if (card.getRecord().get(_this.pointField)) {
                        return card.getRecord().get(_this.pointField).Value || 0;
                    }
                    return 0;
                }
            });
            return {
                progressBarHtml: this._getProgressBarHtml(fraction),
                formattedPercent: fraction.getFormattedPercent(),
                progressBarTitle: this._getProgressBarTitle()
            };
        },

        getDateHeaderTplData: function () {
            var title = 'Date Range';

            return {
                formattedDate: this._getDateRange(),
                titleText: this.editPermissions.timeframeDates ? 'Edit ' + title : title,
                clickableClass: this.editPermissions.timeframeDates ? 'clickable' : ''
            };
        },

        drawHeader: function () {
            this.callParent(arguments);
            this._drawDateRange();
            this._drawProgressBar();
            return this._drawTheme();
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

        _getProgressBarTitle: function () {
            var title = 'Planned Capacity Range';
            return this.editPermissions.capacityRanges ? 'Edit ' + title : title;
        }
    });

})();

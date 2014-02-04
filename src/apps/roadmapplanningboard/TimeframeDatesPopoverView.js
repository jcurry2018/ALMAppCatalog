(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.TimeframeDatesPopoverView', {
        extend: 'Rally.ui.popover.Popover',
        alias: 'widget.capacitypopover',
        requires: [
            'Rally.apps.roadmapplanningboard.util.TimelineViewModel',
            'Rally.ui.picker.DatePicker',
            'Rally.ui.DateField'
        ],
        placement: 'bottom',
        shouldHidePopoverOnBodyClick: false,
        shouldHidePopoverOnIframeClick: false,
        saveOnClose: true,
        closable: false,
        waitTimeForDateFieldValidation: 100,
        cls: 'roadmap-planning-popover',
        chevronPrefixCls: 'roadmap-planning-popover-chevron',
        config: {
            timelineViewModel: null
        },

        initComponent: function () {
            this.items = this._getItems();
            this.callParent(arguments);

            this.addEvents(
                'save'
            );

            this.startDate = this.down('#startDate');
            this.endDate = this.down('#endDate');
        },

        _getItems: function () {
            return [
                {
                    itemId: 'datesPopoverLayout',
                    layout: {
                        type: 'table',
                        align: 'center',
                        columns: 3
                    },
                    items: [
                        {
                            xtype: 'component',
                            html: 'Date Range',
                            cls: 'popoverDateRangeText'
                        },
                        {
                            xtype: 'container',
                            colspan: 2,
                            cellCls: 'date-buttons',
                            // Reverse the order in which we add the buttons to handle floating right in a table cell
                            items: [
                                {
                                    xtype: 'rallybutton',
                                    itemId: 'datesDone',
                                    text: 'Done',
                                    cls: 'primary button small right',
                                    listeners: {
                                        click: this._onDone,
                                        scope: this
                                    }
                                },
                                {
                                    xtype: 'rallybutton',
                                    itemId: 'datesCancel',
                                    text: 'Cancel',
                                    cls: 'secondary dark button small right',
                                    listeners: {
                                        click: this._onCancel,
                                        scope: this
                                    }
                                }
                            ]
                        },
                        this._getDateFieldConfig('start', this.timelineViewModel.currentTimeframe.startDate),
                        {
                            xtype: 'component',
                            html: 'to',
                            cls: 'popoverToText'
                        },
                        this._getDateFieldConfig('end', this.timelineViewModel.currentTimeframe.endDate),
                        {
                            xtype: 'component',
                            itemId: 'dateType',
                            tpl: "<div class='popoverDateText'>{dateType}</div>",
                            colspan: 3
                        }
                    ]
                },
                {
                    xtype: 'component',
                    autoEl: 'div',
                    id: 'startdate-validation-error',
                    cls: ['form-error-msg-field']
                },
                {
                    xtype: 'component',
                    autoEl: 'div',
                    id: 'enddate-validation-error',
                    cls: ['form-error-msg-field']
                }
            ];
        },

        _getDateFieldConfig: function (fieldPrefix, value) {
            var _this = this;
            var displayText = fieldPrefix + ' date';

            return {
                xtype: 'rallydatefield',
                cls: 'dateField',
                itemId: fieldPrefix + 'Date',
                msgTarget: fieldPrefix + 'date-validation-error',
                checkChangeBuffer: this.waitTimeForDateFieldValidation,
                value: value,
                validateOnBlur: false,
                validator: function () {
                    return _this._validateDateRanges(this);
                },
                onTriggerClick: function () {
                    return _this._createPicker(this, displayText);
                },
                listeners: {
                    validitychange: function (dateField, isValid) {
                        var doneButton = this.down('#datesDone');

                        if(isValid) {
                            doneButton.enable();
                        } else {
                            doneButton.disable();
                        }
                    },
                    focus: function (dateField) {
                        if (this.picker && this.picker.dateFieldId !== dateField.itemId) {
                            this._createPicker(dateField, displayText);
                        } else {
                            this._resetAndAddClsToDateField(dateField);
                        }
                    },
                    aftervalidate: function (dateField, isValid) {
                        if (this.picker && isValid) {
                            this.picker.value = dateField.getValue();
                            this._updatePicker(dateField);
                        }
                    },
                    scope: this
                }
            };
        },

        _validateDateRanges: function (dateField) {
            var startDate = dateField.itemId === this.startDate.itemId ? this.startDate.getValue() : this.timelineViewModel.currentTimeframe.startDate;
            var endDate = dateField.itemId === this.endDate.itemId ? this.endDate.getValue() : this.timelineViewModel.currentTimeframe.endDate;

            try {
                this.timelineViewModel.setCurrentTimeframe({
                    startDate: startDate,
                    endDate: endDate
                });
                return true;
            } catch(error) {
                return error;
            }
        },

        _onCancel: function () {
            this.saveOnClose = false;
            this.destroy();
        },

        _onDone: function () {
            this.saveOnClose = true;
            this.destroy();
        },

        destroy: function () {
            if(this.saveOnClose && this.startDate.isValid() && this.endDate.isValid()) {
                this._save();
            }

            this.callParent(arguments);
        },

        _save: function () {
            this.fireEvent('save', {
                startDate: this.timelineViewModel.currentTimeframe.startDate,
                endDate: this.timelineViewModel.currentTimeframe.endDate
            });
        },

        _createPicker: function (dateField, displayText) {
            var _this = this;

            if (this.picker) {
                this.picker.destroy();
            }

            var pickerOpts = {
                xtype: 'rallydatepicker',
                itemId: 'datePicker',
                floating: false,
                hidden: false,
                focusOnShow: false,
                focusOnToFront: false,
                enableMonthPicker: false,
                colspan: 3,
                dateFieldId: dateField.itemId,
                handler: function (picker, date) {
                    dateField.setValue(date);

                    _this._updatePicker(dateField);
                    _this._addDateSelectedTransitions(dateField);
                },
                minDate: this._getPickerMinDate(dateField),
                maxDate: this._getPickerMaxDate(dateField),
                rangeStart: this.timelineViewModel.currentTimeframe.startDate,
                rangeEnd: this.timelineViewModel.currentTimeframe.endDate
            };

            if (dateField.itemId === this.startDate.itemId) {
                pickerOpts.value = this.timelineViewModel.currentTimeframe.startDate;
                pickerOpts.minText = 'This date overlaps an earlier timeframe';
                pickerOpts.maxText = 'This date is after the end date';
            } else {
                pickerOpts.value = this.timelineViewModel.currentTimeframe.endDate;
                pickerOpts.minText = 'This date is before the start date';
                pickerOpts.maxText = 'This date overlaps a later timeframe';
            }

            this.picker = this.down('#datesPopoverLayout').add(pickerOpts);

            this._addPickerClasses();
            this._resetAndAddClsToDateField(dateField);
            this.down('#dateType').update({
                dateType: displayText
            });
        },

        _updatePicker: function (dateField) {
            this.picker.rangeStart = this.timelineViewModel.currentTimeframe.startDate;
            this.picker.rangeEnd = this.timelineViewModel.currentTimeframe.endDate;
            this.picker.update(dateField.getValue(), true);
        },

        _getPickerMinDate: function (dateField) {
            var prevTimeframe = this.timelineViewModel.getPreviousTimeframe();

            if (dateField.itemId === this.endDate.itemId) {
                return this.timelineViewModel.currentTimeframe.startDate;
            }

            if (prevTimeframe) {
                return Ext.Date.add(prevTimeframe.endDate, Ext.Date.DAY, 1);
            }
        },

        _getPickerMaxDate: function (dateField) {
            var nextTimeframe = this.timelineViewModel.getNextTimeframe();

            if (dateField.itemId === this.startDate.itemId) {
                return this.timelineViewModel.currentTimeframe.endDate;
            }

            if (nextTimeframe) {
                return Ext.Date.add(nextTimeframe.startDate, Ext.Date.DAY, -1);
            }
        },

        _addDateSelectedTransitions: function (dateField) {
            dateField.addCls('transition-bg-color');
            dateField.addCls('dateSelected');
            return setTimeout(function () {
                return dateField.removeCls('dateSelected');
            }, 1);
        },

        _resetAndAddClsToDateField: function (dateField) {
            _.each([this.startDate, this.endDate], function (comp) {
                comp.removeCls('triggerSelected');
            });

            dateField.addCls('triggerSelected');
        },

        _addPickerClasses: function () {
            var datePickerPrev = this.picker.getEl().down( '.' + Ext.baseCSSPrefix + 'datepicker-prev');
            datePickerPrev.addCls('icon-chevron-left');

            var datePickerNext = this.picker.getEl().down('.' + Ext.baseCSSPrefix + 'datepicker-next');
            datePickerNext.addCls('icon-chevron-right');

            var todayButton = this.picker.getEl().down('.' + Ext.baseCSSPrefix + 'datepicker-footer .' + Ext.baseCSSPrefix + 'btn');
            todayButton.addCls('secondary');
        }
    });

}).call(this);

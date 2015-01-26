(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.TimeframeDatesPopoverView', {
        extend: 'Rally.ui.popover.Popover',
        alias: 'widget.daterangepopover',
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
        header: false,

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
                                    cls: 'primary button small rly-right',
                                    listeners: {
                                        click: this._onDone,
                                        scope: this
                                    }
                                },
                                {
                                    xtype: 'rallybutton',
                                    itemId: 'datesCancel',
                                    text: 'Cancel',
                                    cls: 'secondary dark button small rly-right',
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
                    cls: ['form-error-msg-field', 'date-range-error-msg-field']
                },
                {
                    xtype: 'component',
                    autoEl: 'div',
                    id: 'enddate-validation-error',
                    cls: ['form-error-msg-field', 'date-range-error-msg-field']
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
                validateOnChange: false,
                validator: function () {
                    return _this._validateDateRanges();
                },
                onTriggerClick: function () {
                    return _this._createPicker(this, displayText);
                },
                listeners: {
                    validitychange: function (dateField, isValid) {
                        if(isValid) {
                            this.down('#datesDone').enable();
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
                            this._updatePicker(dateField, isValid);
                        }

                        if (isValid) {
                            var otherDateField = dateField === this.startDate ? this.endDate : this.startDate;
                            otherDateField.clearInvalid();
                        }
                    },
                    scope: this
                }
            };
        },

        _validateDateRanges: function () {
            var newTimeframe = {
                startDate: this.startDate.getValue(),
                endDate: this.endDate.getValue()
            };

            if (!Ext.isDate(newTimeframe.startDate) || !Ext.isDate(newTimeframe.endDate)) {
                return 'Date fields must contain valid dates';
            }

            if (newTimeframe.startDate > newTimeframe.endDate) {
                return 'Start date is after end date';
            }

            this.timelineViewModel.currentTimeframe = newTimeframe;

            if (this.timelineViewModel.isTimeframeOverlapping(newTimeframe)) {
                return 'Date range overlaps an existing timeframe';
            }

            return true;
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
            if(this.saveOnClose) {
                var startDateValid = this.startDate.isValid();
                var endDateValid = this.endDate.isValid();

                if (startDateValid && endDateValid) {
                    this._save();
                } else {
                    this.startDate.validateOnChange = true;
                    this.endDate.validateOnChange = true;
                    this.down('#datesDone').disable();
                    return false;
                }

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

                    var isValid = _this._dateFieldsValid();
                    _this._updatePicker(dateField, isValid);
                    _this._addDateSelectedTransitions(dateField);
                },
                disabledDateRanges: this.timelineViewModel.timeframes,
                disabledDatesText: 'This date overlaps an existing timeframe'
            };

            if (dateField.itemId === this.startDate.itemId) {
                pickerOpts.value = this.timelineViewModel.currentTimeframe.startDate;
                pickerOpts.maxDate = this.timelineViewModel.currentTimeframe.endDate;
                pickerOpts.maxText = 'This date is after the end date';
            } else {
                pickerOpts.value = this.timelineViewModel.currentTimeframe.endDate;
                pickerOpts.minDate = this.timelineViewModel.currentTimeframe.startDate;
                pickerOpts.minText = 'This date is before the start date';
            }

            this._setPickerRange(pickerOpts, this._dateFieldsValid());

            this.picker = this.down('#datesPopoverLayout').add(pickerOpts);

            this._addPickerClasses();
            this._resetAndAddClsToDateField(dateField);
            this.down('#dateType').update({
                dateType: displayText
            });
        },

        _dateFieldsValid: function () {
            return this._validateDateRanges() === true;
        },

        _updatePicker: function (dateField, isValid) {
            this._setPickerRange(this.picker, isValid);
            this.picker.update(dateField.getValue(), true);
        },

        _setPickerRange: function (picker, isValid) {
            if (isValid) {
                picker.rangeStart = this.timelineViewModel.currentTimeframe.startDate;
                picker.rangeEnd = this.timelineViewModel.currentTimeframe.endDate;
            } else {
                picker.rangeStart = null;
                picker.rangeEnd = null;
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

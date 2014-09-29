(function () {
    var Ext, me;

    Ext = window.Ext4 || window.Ext;

    me = null;

    Ext.define('Rally.apps.roadmapplanningboard.PlanningCapacityPopoverView', {
        extend: 'Rally.ui.popover.Popover',
        alias: 'widget.capacitypopover',
        modal: false,
        placement: 'bottom',
        shouldHidePopoverOnBodyClick: true,
        shouldHidePopoverOnIframeClick: true,
        saveOnClose: true,
        cls: 'roadmap-planning-popover',
        chevronPrefixCls: 'roadmap-planning-popover-chevron',
        config: {
            model: null
        },
        header: false,

        initComponent: function () {
            this.items = this._getItems();
            this.callParent(arguments);

            this.lowCapacity = this.down('#low-capacity-field');
            this.highCapacity = this.down('#high-capacity-field');
        },

        _getItems: function() {
            return [
                {
                    layout: {
                        type: 'table',
                        align: 'center',
                        columns: 2
                    },
                    items: [
                        {
                            xtype: 'component',
                            html: 'Planned Capacity Range',
                            cls: 'popover-label',
                            colspan: 2
                        },
                        this._getNumberField({
                            itemId: 'low-capacity-field',
                            fieldLabel: 'Low',
                            name: 'lowCapacity',
                            msgTarget: 'capacity-validation-error',
                            padding: '0 13 0 0'
                        }, this.model.get('lowCapacity')),
                        this._getNumberField({
                            itemId: 'high-capacity-field',
                            fieldLabel: 'High',
                            name: 'highCapacity'
                        }, this.model.get('highCapacity'))
                    ]
                },
                {
                    xtype: 'container',
                    cls: 'capacity-buttons',
                    items: [
                        {
                            xtype: 'rallybutton',
                            itemId: 'capacityCancel',
                            text: 'Cancel',
                            cls: 'secondary dark button small rly-right',
                            listeners: {
                                click: this._onCancel,
                                scope: this
                            }
                        },
                        {
                            xtype: 'rallybutton',
                            itemId: 'capacityDone',
                            text: 'Done',
                            cls: 'primary button small rly-right',
                            listeners: {
                                click: this._onDone,
                                scope: this
                            }
                        }
                    ]
                },
                {
                    xtype: 'component',
                    autoEl: 'div',
                    id: 'capacity-validation-error',
                    cls: ['form-error-msg-field', 'capacity-error-msg-field']
                }
            ];
        },

        _getNumberField: function(config, value) {
            var _this = this;

            return _.merge({xtype: 'numberfield',
                value:  value,
                hideTrigger: true,
                minValue: 0,
                maxLength: 4,
                enforceMaxLength: true,
                maxLengthText: '',
                maxValue: 9999,
                maxText: '',
                allowDecimals: false,
                validateOnBlur: false,
                validateOnChange: false,
                validator: function () {
                    return _this._validateRange();
                },
                labelAlign: 'left',
                labelWidth: 34,
                labelPad: 0,
                width: '80px',
                listeners: {
                    validitychange: this._validityChange,
                    scope: this
                }
            }, config);
        },

        _validityChange: function (capacityField, isValid) {
            if(isValid) {
                this.down('#capacityDone').enable();
                this.lowCapacity.validateOnChange = false;
                this.highCapacity.validateOnChange = false;

                this.lowCapacity.clearInvalid();
                this.highCapacity.clearInvalid();
            }
        },

        _validateRange: function () {
            var lowValue = this.lowCapacity.getValue();
            var highValue = this.highCapacity.getValue();

            return highValue >= lowValue ? true : 'Low estimate should not exceed the high estimate';
        },

        _onCancel: function () {
            this.saveOnClose = false;
            this.destroy();
        },

        _onDone: function () {
            this.saveOnClose = true;
            this.destroy();
        },

        _save: function () {
            var requester;
            this.model.set('lowCapacity', this.lowCapacity.getValue());
            this.model.set('highCapacity', this.highCapacity.getValue());

            if (this.view && this.view.owner && this.view.owner.ownerCardboard) {
                requester = this.view.owner.ownerCardboard;
            }
            this.model.save({
                requester: requester
            });
        },

        destroy: function () {
            if(this.saveOnClose) {
                if (this.lowCapacity.validate() && this.highCapacity.validate()) {
                    this._save();
                } else {
                    this.lowCapacity.validateOnChange = true;
                    this.highCapacity.validateOnChange = true;
                    this.down('#capacityDone').disable();
                    return false;
                }

            }

            this.callParent(arguments);
        }
    });

}).call(this);

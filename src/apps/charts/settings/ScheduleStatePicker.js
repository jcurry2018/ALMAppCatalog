(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define("Rally.apps.charts.settings.ScheduleStatePicker", {
        extend: "Ext.form.FieldContainer",
        alias: "widget.chartschedulestatepicker",

        requires: [
            "Ext.data.Store",
            "Ext.form.field.ComboBox",
            "Rally.ui.picker.MultiObjectPicker"
        ],

        settingsParent: undefined,

        config: {
            settingName: "customScheduleStates"
        },

        initComponent: function() {
            this.callParent(arguments);
            this._loadUserStoryModel();
        },

        _loadUserStoryModel: function() {
            Rally.data.ModelFactory.getModel({
                type: "UserStory",
                context: this._getContext(),
                success: this._addPicker,
                scope: this
            });
        },

        _getContext: function() {
            return {
                workspace: this.context.getWorkspaceRef(),
                project: null
            };
        },

        _addPicker: function(userStoryModel) {
            this.add({
                xtype: "combobox",
                name:  this.settingName,
                store: Ext.create('Ext.data.JsonStore', {
                    fields: ['StringValue'],
                    data: _.map(userStoryModel.getField('ScheduleState').getAllowedStringValues(), function(scheduleState) {
                        return {
                            StringValue: scheduleState
                        };
                    })
                }),
                valueField: "StringValue",
                displayField: "StringValue",
                queryMode: "local",
                multiSelect: true,
                listConfig: {
                    cls: "schedule-state-selector",
                    tpl: Ext.create('Ext.XTemplate',
                        '<tpl for=".">',
                            '<li role="option" class="' + Ext.baseCSSPrefix + 'boundlist-item">',
                                '<input type="button" class="' + Ext.baseCSSPrefix + 'form-checkbox" /> &nbsp;',
                                '{StringValue}',
                            '</li>',
                        '</tpl>'
                    )
                },
                listeners: {
                    beforerender: this._onComboboxBeforeRender,
                    scope: this
                }
            });
        },

        _onComboboxBeforeRender: function(combobox) {
            var stringValue = this.settingsParent.app.getSetting(this.settingName),
                values = [];

            if(_.isString(stringValue)) {
                values = stringValue.split(",");
            }

            combobox.setValue(values);
        }
    });
}());
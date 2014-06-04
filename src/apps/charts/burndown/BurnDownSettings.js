(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define("Rally.apps.charts.burndown.BurnDownSettings", {
        requires: [
            "Rally.apps.charts.settings.ChartDisplayTypePicker",
            "Rally.apps.charts.settings.DataTypePicker",
            "Rally.apps.charts.settings.TimeboxPicker",
            "Rally.ui.CheckboxField"
        ],

        config: {
            app: undefined
        },
        
        constructor: function (config) {
            this.mergeConfig(config);
        },

        _buildSettingsComponent: function (type, label, name) {
            var self = this;

            var componentAdded = function (cmp) {
                this.settingsParent = this.settingsParent || self;
            };

            var settings = {
                xtype: type,
                label: label,
                listeners: {
                    added: componentAdded
                }
            };
            if (name) {
                settings.name = name;
                settings.cls = "settings-" + name;
            }
            return settings;
        },

        _isOnScopedDashboard: function() {
            return this.app.isOnScopedDashboard() && !!this.app.context.getTimeboxScope();
        },

        getFields: function() {
            var dataTypePicker = this._buildSettingsComponent("chartdatatypepicker", "Data Type"),
                displayPicker = this._buildSettingsComponent("chartdisplaytypepicker", "Chart Type"),
                timeboxPicker = this._buildSettingsComponent("charttimeboxpicker", "Level"),
                labelNameVisible = this._buildSettingsComponent("rallycheckboxfield", "Show Iteration Labels", 'showLabels');
            
            if(this._isOnScopedDashboard()) {
                return [dataTypePicker, displayPicker, labelNameVisible];
            } else {
                return [timeboxPicker, dataTypePicker, displayPicker, labelNameVisible];
            }
        }
        

    });
}());

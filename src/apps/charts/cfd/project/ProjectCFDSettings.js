(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define("Rally.apps.charts.cfd.project.ProjectCFDSettings", {
        requires: [
            "Rally.apps.charts.settings.StateFieldPicker",
            "Rally.apps.charts.settings.ProjectPicker",
            "Rally.ui.datetime.TimeFrame"
        ],

        config: {
            app: undefined // Parent RallyApp instance
        },

        constructor: function (config) {
            this.mergeConfig(config);
        },

        _getTimeFrame: function () {
            return {
                xtype: "rallytimeframe",
                name: "timeFrame",
                label: "Time Frame",
                mapsToMultiplePreferenceKeys: [ "timeFrameQuantity", "timeFrameUnit" ]
            };
        },

        _getStatePicker: function () {
            return {
                xtype: 'rallychartssettingsstatefieldpicker',
                name: 'stateField',
                settings: this.config.app.getSettings()
            };
        },

        getFields: function () {
            return [
                this._getStatePicker(),
                this._getTimeFrame()
            ];
        }
    });
}());

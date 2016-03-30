(function () {
	var Ext = window.Ext4 || window.Ext;
    /**
     * This is the bridge API that is used by the Alm Shim Environment class (in analytics-easel).
     * This class provides information about the ALM runtime environment and context as well
     * as managing the shuffling of settings around.
     *
     * this.almBridge = Ext.create("Rally.apps.chartbuilder.EaselAlmBridge", {
     *   chartType : chartToLoad, < string value >
     *   app: this < a reference to the app, or something that has getSettings() and getContext()
     *  });
     */
	Ext.define("Rally.apps.chartbuilder.EaselAlmBridge", {

		requires: ['Rally.apps.chartbuilder.EaselSettingsTransformer'],

		defaultSettings: {},

		/**
		 * These are the settings fields coming from the chart definition
		 */
		easelSettingsFields: {},

		config: {
			chartType: 'none',
			/**
			 *  settings from which getSetting is delivered. it's assumed this structure
			 *  is updated in place and is passed in during construction from the app
			 */
			app: null
		},

		transformer: Ext.create("Rally.apps.chartbuilder.EaselSettingsTransformer"),

		constructor: function(config) {
			this.initConfig(config);
		},

		getApp: function() {
			return this.config.app || {
				getSettings : function() { return {}; },
				getContext : function() { return Rally.environment.getContext(); }
			};
		},

		showSettings: function() {
			this.app.triggerSettingsMode();
		},

		lbapiBaseUrl: function() {
			return Rally.environment.getServer().getLookbackUrl();
		},

		wsapiBaseUrl: function() {
			return Rally.environment.getServer().getWsapiUrl();
		},

		getProjectScopingDown: function() {
			return this.getContext().getProjectScopeDown();
		},

		getWorkspace: function() {
			return this.getContext().getWorkspace();
		},

		getProject: function() {
			return this.getContext().getProject();
		},

		log: function(a,b) {
			var c = console;
			c.log(a,b);
		},

		getSetting: function(name) {
			return this.transformer.getValue(this.easelSettingsFields, this.getAppSettings(), name);
		},

		getSettings: function() {
			return this.transformer.getValues(this.easelSettingsFields, this.getAppSettings());
		},

		getContext: function() {
			return this.getApp().getContext();
		},

		getAppSettings: function() {
			return this.getApp().getSettings();
		},

		getDefaultSettings: function() {
			return this.defaultSettings;
		},

		getSettingsFields: function() {
			var listOfTransformedSettings = this.transformer.transform(this.easelSettingsFields);
			return listOfTransformedSettings;
		},

		registerSettingsFields: function(easelSettingsFields) {
			// var self = this;
			this.easelSettingsFields = easelSettingsFields;
			this.defaultSettings = this.transformer.transformDefaults(easelSettingsFields);
		},

		getChartType: function() {
			return this.config.chartType;
		},

		setLoading: function(isLoading) {
			this.getApp().setLoading(isLoading);
		}
	});
}());

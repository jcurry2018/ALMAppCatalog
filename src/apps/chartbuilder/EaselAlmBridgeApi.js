(function () {
	var Ext = window.Ext4 || window.Ext;
    /**
     * This is the bridge API that is used by the Alm Shim Environment class (in analytics-easel).
     * This class provides information about the ALM runtime environment and context as well
     * as managing the shuffling of preferences around.
     *
     * this.almBridge = Ext.create("Rally.apps.chartbuilder.EaselAlmBridgeApi", {
     *   chartType : chartToLoad, < string value >
     *   app: this < a reference to the app, or something that has getSettings() and getContext()
     *  });
     */
	Ext.define("Rally.apps.chartbuilder.EaselAlmBridgeApi", {

		requires: ['Rally.apps.chartbuilder.EaselPreferenceTransformer'],

		defaultSettings : {},
		easelPreferences : {},
		config: {
			chartType : 'none',
			/**
			 *  settings from which getPreference is delivered. it's assumed this structure
			 *  is updated in place and is passed in during construction from the app
			 */
			app: null
		},

		transformer: Ext.create("Rally.apps.chartbuilder.EaselPreferenceTransformer"),

		constructor: function(config) {
			this.initConfig(config);
		},

		getApp : function() {
			return this.config.app || {
				getSettings : function() { return {}; },
				getContext : function() { return Rally.environment.getContext(); }
			};
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

		getPreference : function(name) {
			return this.transformer.getValue(this.easelPreferences, this.getSettings(), name);
		},

		getContext : function() {
			return this.getApp().getContext();
		},

		getSettings : function() {
			return this.getApp().getSettings();
		},

		getDefaultSettings : function() {
			return this.defaultSettings;
		},

		getSettingsFields : function() {
			var listOfTransformedSettings = this.transformer.transform(this.easelPreferences);
			return listOfTransformedSettings;
		},

		registerPreferences : function(easelPreferences) {
			var self = this;

			this.easelPreferences = easelPreferences;
			this.defaultSettings = self.defaultSettings;

			_.each(this.easelPreferences, function(pref) {
				if (pref['default']) {
					self.defaultSettings[pref.name] = pref['default'];
				}
			});
		},

		getChartType: function() {
			return this.config.chartType;
		},

		setLoading: function(isLoading) {
			this.getApp().setLoading(isLoading);
		}
	});
}());

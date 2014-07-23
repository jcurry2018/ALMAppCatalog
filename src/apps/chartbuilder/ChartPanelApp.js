(function () {
	var Ext = window.Ext4 || window.Ext;

	Ext.define("Rally.apps.chartbuilder.ChartPanelApp", {
		name: 'rally-cbchart-app',
		extend: "Rally.app.App",
		componentCls: 'cbchart-app',
		config: {
			defaultSettings: {
				url: ''
			}
		},
		requires: [],
		items: [
			{
				xtype: 'container',
				itemId: 'mrcontainer',
				cls: 'mrcontainer'
			}
		],

		help: {
			id: 279
		},

		settingsTransformers: {
			'combobox': function(original) {
				return {
					xtype: 'rallycombobox',
					valueField: 'value',
					displayField: 'label',
					name: original.name,
					store: {
						xtype: "store",
						fields: [
							'label','value'
						],
						data: original.values || [{label:'data expected is \'label\' and \'value\'',value:''}]
					}
				};
			}
		},

		getSettingsFields: function () {
			var fields = this.callParent(arguments);

			fields.push({
				type: "text",
				name: "url",
				label: "URL To Load"
			});

			var self = this;

			_.each(this.appPrefs, function(pref) {
				var p = pref;
				if (self.settingsTransformers[pref.type]) {
					p = self.settingsTransformers[pref.type](pref);
				}
				fields.push(p);
			});

			return fields;
		},

		getDefaultSettings: function() {
			var defaults = this.callParent(arguments);
			_.each(this.appPrefs, function(pref) {
				defaults[pref.name] = pref['default'];
			});
			return defaults;
		},

		constructIFrame: function() {
			var ifr = '<iframe width="100%" height="480" src="/analytics/chart/latest/almshim.html"></iframe>';
			this.down("#mrcontainer").el.dom.innerHTML = ifr;
		},

		render: function () {
			var self = this;
			this.callParent(arguments);

			this.constructIFrame();
			// create the API that will be passed in (the execution context if you will) to the
			// chart that's loaded

			// feature toggles are an ENVIRONMENT/shim specific thing and are NOT
			// exposed to the chart apps. ??? it seems like maybe chart apps could
			// still make use of toggles.?
			var iframe = this.down('#mrcontainer').el.dom.firstChild;

			var chartToLoad = this.appContainer.slug;

			// provide port(s) for the chart app to use
			var almBridge = {
				lbapiBaseUrl: function() {
					return Rally.environment.getServer().getLookbackUrl();
				},

				wsapiBaseUrl: function() {
					return Rally.environment.getServer().getWsapiUrl();
				},

				getProjectScopingDown: function() {
					return self.getContext().getProjectScopeDown();
				},

				getWorkspace: function() {
					return self.getContext().getWorkspace();
				},

				getProject: function() {
					return self.getContext().getProject();
				},

				//toggleEnabled : function(name) { return false;},
				//getPreference: function(n) {
				//	return self.getSetting(n) || self.defaultSettings[n];
				//},
				log: function(a,b) {
					var c = console;
					c.log(a,b);
				},
				//registerPreferences : function(easelPreferences) {
				//	self.appPrefs = easelPreferences;
				//	_.each(self.appPrefs, function(pref) {
				//		if (pref['default']) {
				//			self.defaultSettings[pref.name] = pref['default'];
				//		}
				//	});
				//},
				getChartType: function() {
					return chartToLoad;
				}
			};

			iframe.almBridge = almBridge;

			// example - binding events to the chart app
			Ext.EventManager.onWindowResize(function() {
				if (self.chart && self.chart.onResize) {
					self.chart.onResize();
				}
			}, this);

		}
	});

}());

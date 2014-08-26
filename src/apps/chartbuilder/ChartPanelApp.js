(function () {
	var Ext = window.Ext4 || window.Ext;

	Ext.define('Rally.apps.chartbuilder.ChartPanelApp', {
		name: 'rally-cbchart-app',
		extend: 'Rally.app.App',
		componentCls: 'cbchart-app',
		config: {
		},
		/** any xtypes being used by settings (in the chart) need to be put here */
		requires: [
			'Rally.apps.chartbuilder.EaselAlmBridge',
			'Rally.ui.combobox.MilestoneComboBox'
		],
		items: [
			{
				xtype: 'container',
				itemId: 'mrcontainer',
				cls: 'mrcontainer'
			}
		],

		getSettingsFields: function () {
			var fields = this.callParent(arguments) || [];
			// get the settings fields that the chart requires
			var listOfTransformedSettings = this.almBridge.getSettingsFields();
			return fields.concat(listOfTransformedSettings);
		},

		getDefaultSettings: function() {
			var defaults = this.callParent(arguments);
			var defaultsFromEaselChart = this.almBridge.getDefaultSettings();
			return Ext.apply( defaults, defaultsFromEaselChart, {} );
		},

		getUrlSearchString: function() {
			return location.search || '';
		},

		isDebugMode: function() {
			var parameters = Ext.Object.fromQueryString(this.getUrlSearchString());
			return parameters.packtag === 'false';
		},

		getChartVersionFromRequest: function() {
			var parameters = Ext.Object.fromQueryString(this.getUrlSearchString());
			return (parameters.chartVersion || 'latest');
		},

		constructIFrame: function() {
			var filename = this.isDebugMode() ? 'almchart.html' : 'almchart.min.html';
			var version = this.getChartVersionFromRequest();
			var ifr = '<iframe width="100%" height="480" src="/analytics/chart/' + version + '/' + filename + '"></iframe>';
			this.down("#mrcontainer").el.dom.innerHTML = ifr;
		},

		render: function () {
			this.callParent(arguments);

			this.constructIFrame();
			// create the bridge that will be passed in (the execution context if you will) to the
			// chart that's loaded

			// feature toggles are an ENVIRONMENT/shim specific thing and are NOT
			// exposed to the chart apps. ??? it seems like maybe chart apps could
			// still make use of toggles.?
			var iframe = this.down('#mrcontainer').el.dom.firstChild;

			var chartToLoad = this.appContainer.slug;

			this.almBridge = Ext.create('Rally.apps.chartbuilder.EaselAlmBridge', {
				chartType : chartToLoad,
				app: this
			});

			iframe.almBridge = this.almBridge;
		}
	});

}());

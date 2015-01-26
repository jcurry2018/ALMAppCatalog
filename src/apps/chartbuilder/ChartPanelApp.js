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
			'Rally.ui.combobox.MilestoneComboBox',
			"Rally.apps.chartbuilder.StateFieldPicker",
			'Rally.util.Help'
		],
		autoScroll: false,

		layout: {
			type: 'border',
			align : 'stretch',
			pack  : 'start'
		},
		items: [
			{
				xtype: 'container',
				itemId: 'header',
				cls: 'header',
				region: 'north'
			},
			{
				xtype: 'container',
				itemId: 'mrcontainer',
				cls: 'mrcontainer',
				region: 'center',
				layout: 'fit'
			}
		],

		showSettings: function() {
			// this feels like a hack
			this.owner.defaultSettings = this.getDefaultSettings();
			this.owner.showSettings();
		},

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
		/**
		 * returns true if 'packtag=false' in the query parameters.
		 */
		isDebugMode: function() {
			var parameters = Ext.Object.fromQueryString(this.getUrlSearchString());
			return parameters.packtag === 'false';
		},
		/**
		 * returns the parameter value for 'chartVersion', otherwise 'latest' is
		 * returned.
		 */
		getChartVersionFromRequest: function() {
			var parameters = Ext.Object.fromQueryString(this.getUrlSearchString());
			return (parameters.chartVersion || 'releases/current');
		},
		/**
		 * Builds an iframe in the panel, using the version from getChartVersionFromRequest
		 * to build the path /analytics/chart/$version/almchart.min.html or
		 * if isDebugMode returns true, then almchart.html
		 */
		constructIFrame: function() {
			var filename = this.isDebugMode() ? 'almchart.html' : 'almchart.min.html';
			var version = this.getChartVersionFromRequest();
			var url = '/analytics/chart/' + version + '/' + filename + '?_gen=' + this._getCacheGeneration();
			var ifr = '<iframe frameborder="0" style="overflow:hidden;" width="100%" height="100%" src="' + url + '"></iframe>';
			this.down("#mrcontainer").el.dom.innerHTML = ifr;
		},

		_chartTypeFromSlug: function(slug) {
			return slug.substring(slug.lastIndexOf('/') + 1);
		},
		/**
		 *	Rally.util.Help is not dynamic.  But if we add a panel definition
		 *  we want to add a link to help dynamically, so we check for the
		 *  given help topic in Rally.util.Help and if it's not found, we register
		 *  it.
		 */
		_maybeRegisterHelpTopic: function() {
			var resourceId = this._helpResource();
			var topic = Rally.util.Help.findTopic({resource:resourceId});
			if (!topic) {
				Rally.util.Help.topics.push({
					resource: resourceId,
					url: resourceId
				});
			}
		},
		/**
		 * Return true if the ChartPanelApp has been constructed with help in the config.
		 * A string value is expected.
		 */
		_hasHelp: function() {
			return !!this.config.help && Ext.isString(this.config.help);
		},
		/**
		 * Pull the help string value that is used to register/find the
		 * help topic in Rally.util.Help.
		 */
		_helpResource: function() {
			return this.config.help;
		},
		/**
		 * Adds an icon link to the header.  The help 'topic'
		 * is pulled via the _helpResource method.  Rally.util.Help is used
		 * to format the help link.
		 */
		_buildHelpComponent: function () {
			this._maybeRegisterHelpTopic();

			var help = this._helpResource();

			return Ext.create('Ext.Component', {
				itemId: 'helpicon',
				renderTpl: Rally.util.Help.getIcon({
					resource: help
				})
			});
		},

		_slugValue: function() {
			return this.appContainer.slug;
		},

		_getCacheGeneration : function(theDate) {
			theDate = theDate || new Date();
			return Ext.Date.format(theDate, 'YmdH');
		},
		/**
		 * Conditionally constructs the help component in the header.
		 */
		launch: function() {
			this.callParent(arguments);
			if (this._hasHelp()) {
				this.down('#header').add(this._buildHelpComponent());
			}
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

			var chartToLoad = this._chartTypeFromSlug(this.appContainer.slug);

			this.almBridge = Ext.create('Rally.apps.chartbuilder.EaselAlmBridge', {
				chartType : chartToLoad,
				app: this
			});

			iframe.almBridge = this.almBridge;
		}
	});

}());

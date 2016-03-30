(function () {
	var Ext = window.Ext4 || window.Ext;

	Ext.define('Rally.apps.chartbuilder.ChartPanelApp', {
		name: 'rally-cbchart-app',
		extend: 'Rally.app.App',
		componentCls: 'cbchart-app',
		config: {
			height:'100%',
			width:'100%'
		},
		items: [{
			xtype: 'container',
			itemId: 'header',
			cls: 'header'
		}],
		/** any xtypes being used by settings (in the chart) need to be put here */
		requires: [
			'Rally.apps.chartbuilder.EaselAlmBridge',
			'Rally.ui.combobox.MilestoneComboBox',
			'Rally.ui.picker.StateFieldPicker',
			'Rally.util.Help'
		],
		autoScroll: false,
		projectScopeable: false,

		initComponent: function() {
			this.callParent(arguments);
			this.add([
				{
					xtype: 'container',
					itemId: 'mrcontainer',
					cls: 'mrcontainer',
					width:'100%',
					height: this._hasHelp() ? '90%' : '99%'
				}
			]);
		},

		triggerSettingsMode: function() {
			this.defaultSettings = this.getDefaultSettings();
			this.fireEvent('settingsneeded', this);
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
			return (parameters.chartVersion || '0.3.9');
		},
		/**
		 * Builds an iframe in the panel, using the version from getChartVersionFromRequest
		 * to build the path /assets/burro/queso/$version/almchart.min.html or
		 * if isDebugMode returns true, then almchart.html
		 */
		constructIFrame: function() {
			var filename = this.isDebugMode() ? 'almchart.html' : 'almchart.min.html';
			var version = this.getChartVersionFromRequest();
			var url = this._getQuesoUrl() + '/' + version + '/' + filename;
			var ifr = '<iframe frameborder="0" style="overflow:hidden;" scrolling="no" width="100%" height="100%" src="' + url + '"></iframe>';
			this.down("#mrcontainer").el.dom.innerHTML = ifr;
		},

		_getChartType: function() {
			if(!this.getContext().isFeatureEnabled('F6971_REACT_DASHBOARD_PANELS')) {
				return this.appContainer.slug.split('/').pop();
			} else {
				return this.chartType;
			}
		},

		_getQuesoUrl: function() {
			return window.burroUrl + '/queso';
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

			this.almBridge = Ext.create('Rally.apps.chartbuilder.EaselAlmBridge', {
				chartType : this._getChartType(),
				app: this
			});

			iframe.almBridge = this.almBridge;
		}
	});

}());

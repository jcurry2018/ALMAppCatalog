(function () {
	var Ext = window.Ext4 || window.Ext;

	Ext.define("Rally.apps.chartbuilder.EaselPreferenceTransformer", {


		settingsFieldTransformers: {
			'project-select': function(easelPreferenceSpec) {
				return {
					type: "project",
					name: easelPreferenceSpec.name,
					label: "Project"
				};
			},
			'combobox': function(easelPreferenceSpec) {
				return {
					xtype: 'rallycombobox',
					valueField: 'value',
					displayField: 'label',
					name: easelPreferenceSpec.name,
					store: {
						xtype: "store",
						fields: [
							'label','value'
						],
						data: easelPreferenceSpec.values || [{label:'data expected is \'label\' and \'value\'',value:''}]
					}
				};
			}
		},

		/**
		 * A list of functions that convert what's in the app's 'settings'
		 * to a value for the given 'key'
		 */
		settingsTransformers: {
			'project-select' : function(settings, key) {
				// key is ignored in 'project-select' because the
				// project scope field doesn't honor it's 'name'. it just
				// pollutes the settings with project, projectScopeUp and projectScopeDown
				if (!settings.project || '' === settings.project) {
					return null;
				}
				return {
					project: parseInt(settings.project.match(/\d+/),10),
					scopeUp : (settings.projectScopeUp === 'true'),
					scopeDown : (settings.projectScopeDown === 'true')
				};
			}
		},

		/**
		 * Based on the easelPreference definitions and the values that have been
		 * pushed into 'settings' from the ALM Settings Mechanism, return a
		 * value for the 'key' provided.  In the case of a 'project-select',
		 * the value is an object that has project,scopeUp and scopeDown OR null
		 * if 'follow global' is selected.
		 */
		getValue: function(easelPreferences, settings, key) {
			// based on the easelPreference definitions,
			// interrogate settings to find the property value for 'key'
			var pref = _.find(easelPreferences, function(pref) {
				return key === pref.name;
			});
			if (!pref) { return null; }

			if (this.settingsTransformers[pref.type]) {
				return this.settingsTransformers[pref.type](settings, key);
			} else {
				return settings[pref.name];
			}

		},
		/**
		 * takes in an easel 'preferences' block and transforms it into a list
		 * of settings that are appropriate for use within the ALM application
		 * settings mechanism.
		 * see the list of settingsFieldTransformers above.
		 */
		transform: function(easelPreferences) {
			var self = this;
			var fields = [];
			if (! Array.isArray(easelPreferences)) {
				return fields;
			}

			_.each(easelPreferences, function(pref) {
				var p = pref;
				if (self.settingsFieldTransformers[pref.type]) {
					p = self.settingsFieldTransformers[pref.type](pref);
				}
				fields.push(p);
			});
			return fields;
		}
	});
}());

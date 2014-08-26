(function () {
	var Ext = window.Ext4 || window.Ext;

	Ext.define("Rally.apps.chartbuilder.EaselSettingsTransformer", {

		settingsFieldTransformers: {
			'milestone-picker': function(easelSettingsField) {
				return {
					xtype: "rallymilestonecombobox",
					name: easelSettingsField.name,
					label: "Milestone"
				};
			},
			'project-picker': function(easelSettingsField) {
				return {
					type: "project",
					name: easelSettingsField.name,
					label: "Project"
				};
			},
			'combobox': function(easelSettingsField) {
				return {
					xtype: 'rallycombobox',
					valueField: 'value',
					displayField: 'label',
					name: easelSettingsField.name,
					store: {
						xtype: "store",
						fields: [
							'label','value'
						],
						data: easelSettingsField.values || [{label:'data expected is \'label\' and \'value\'',value:''}]
					}
				};
			}
		},

		/**
		 * A list of functions that convert what's in the app's 'settings'
		 * to a value for the given 'key'
		 */
		settingsTransformers: {
			'milestone-picker' : function(settings, key) {
				var val = settings[key];
				if (!val || '' === val) {
					return null;
				}
				return parseInt(val.match(/\d+/),10);
			},

			'project-picker' : function(settings, key) {
				// key is ignored in 'project-picker' because the
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
		 * value for the 'key' provided.  In the case of a 'project-picker',
		 * the value is an object that has project,scopeUp and scopeDown OR null
		 * if 'follow global' is selected.
		 */
		getValue: function(easelSettingsFields, settings, key) {
			// based on the easelPreference definitions,
			// interrogate settings to find the property value for 'key'
			var settingsField = _.find(easelSettingsFields, function(settingsField) {
				return key === settingsField.name;
			});
			return this.convert(settingsField, settings);
		},

		getValues: function(easelSettingsFields, settings) {
			// based on the easelPreference definitions,
			// interrogate settings to find the property value for 'key'
			var result = {};

			var _this = this;
			_.each(easelSettingsFields, function(settingsField) {
				var value = _this.convert(settingsField, settings);
				if (value) {
					result[settingsField.name] = value;
				}
			});

			return result;
		},

		convert: function(settingsField, settings) {
			if (!settingsField) { return null; }

			if (this.settingsTransformers[settingsField.type]) {
				return this.settingsTransformers[settingsField.type](settings, settingsField.name);
			} else {
				return settings[settingsField.name];
			}
		},
		/**
		 * takes in an easel 'preferences' block and transforms it into a list
		 * of settings that are appropriate for use within the ALM application
		 * settings mechanism.
		 * see the list of settingsFieldTransformers above.
		 */
		transform: function(easelSettingsFields) {
			var self = this;
			var fields = [];
			if (! Array.isArray(easelSettingsFields)) {
				return fields;
			}

			_.each(easelSettingsFields, function(settingsField) {
				var p = settingsField;
				if (self.settingsFieldTransformers[settingsField.type]) {
					p = self.settingsFieldTransformers[settingsField.type](settingsField);
				}
				fields.push(p);
			});
			return fields;
		}
	});
}());

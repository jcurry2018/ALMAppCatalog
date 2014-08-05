(function () {
	var Ext = window.Ext4 || window.Ext;

	Ext.define("Rally.apps.chartbuilder.EaselPreferenceTransformer", {


		settingsTransformers: {
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
		 * takes in an easel 'preferences' block and transforms it into a list
		 * of settings that are appropriate for use within the ALM application
		 * settings mechanism.
		 * see the list of settingsTransformers above.
		 */
		transform: function(easelPreferences) {
			var self = this;
			var fields = [];
			if (! Array.isArray(easelPreferences)) {
				return fields;
			}

			_.each(easelPreferences, function(pref) {
				var p = pref;
				if (self.settingsTransformers[pref.type]) {
					p = self.settingsTransformers[pref.type](pref);
				}
				fields.push(p);
			});
			return fields;
		}
	});
}());

Ext = window.Ext4 || window.Ext

Ext.require [
	'Rally.apps.chartbuilder.EaselPreferenceTransformer'
]

describe 'Rally.apps.chartbuilder.EaselPreferenceTransformer', ->

	helpers
		createXformer: ->
			return Ext.create 'Rally.apps.chartbuilder.EaselPreferenceTransformer'

	beforeEach ->
		@xformer = @createXformer()

	it 'converts combobox into rallycombobox', ->
		preferences = [
			{
				type: 'combobox',
				name: 'color',
				label: 'Color Fool',
				default: 'red',
				values: [
					{label:'Red', value: 'red'},
					{label:'Blue', value: 'blue'},
					{label:'Black', value: 'black'}
				]
			}
		]

		expected = [
			{
				"xtype":"rallycombobox"
				"valueField":"value"
				"displayField":"label"
				"name":"color"
				"store":
					"xtype":"store"
					"fields":["label","value"]
					"data":[
						{"label":"Red","value":"red"}
						{"label":"Blue","value":"blue"}
						{"label":"Black","value":"black"}
					]
			}
		]

		converted = @xformer.transform(preferences)
		expect(converted).toEqual expected

	it 'does nothing to textbox', ->
		preferences = [
			{
				type: 'text',
				name: 'chart-title',
				label: 'Chart Title',
				default: 'Chart Title'
			}
		]

		converted = @xformer.transform(preferences)
		expect(converted).toEqual preferences

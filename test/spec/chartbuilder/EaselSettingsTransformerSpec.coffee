Ext = window.Ext4 || window.Ext

Ext.require [
	'Rally.apps.chartbuilder.EaselSettingsTransformer'
]

describe 'Rally.apps.chartbuilder.EaselSettingsTransformer', ->

	helpers
		createXformer: ->
			return Ext.create 'Rally.apps.chartbuilder.EaselSettingsTransformer'

	beforeEach ->
		@xformer = @createXformer()

	it 'properly handles an empty settings fields list', ->
		settingsFields = []
		expected = []

		converted = @xformer.transform(settingsFields)
		expect(converted).toEqual expected

	it 'properly handles a null settings fields list', ->
		settingsFields = null
		expected = []

		converted = @xformer.transform(settingsFields)
		expect(converted).toEqual expected

	it 'converts combobox into rallycombobox', ->
		settingsFields = [
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

		converted = @xformer.transform(settingsFields)
		expect(converted).toEqual expected

	it 'does nothing to textbox', ->
		settingsFields = [
			{
				type: 'text',
				name: 'chart-title',
				label: 'Chart Title',
				default: 'Chart Title'
			}
		]

		converted = @xformer.transform(settingsFields)
		expect(converted).toEqual settingsFields



	it 'converts project-picker into settings project picker', ->
		settingsFields = [
			{ type: 'project-picker', name: 'xyzy' }
		]

		expected = [
			{
				type: 'project'
				name: 'xyzy'
				label: 'Project'
			}
		]

		converted = @xformer.transform(settingsFields)
		expect(converted).toEqual expected


	it 'should convert flat project-picker settings to a nice object', ->
		settingsFields = [
			{ type: 'project-picker', name:'zzzz' }
		]

		settings=
			project: '/project/1234'
			projectScopeUp : 'true'
			projectScopeDown: 'false'

		key = 'zzzz'

		value = @xformer.getValue(settingsFields, settings, key)
		expect(value.project).toBe 1234
		expect(value.scopeUp).toBe true
		expect(value.scopeDown).toBe false


	it 'should convert all values', ->
		settingsFields = [
			{ type: 'project-picker', name:'zzzz' },
			{ type: 'text', name:'yyyy' }
		]

		settings=
			yyyy: 'wassup?'
			project: '/project/1234'
			projectScopeUp : 'true'
			projectScopeDown: 'false'


		value = @xformer.getValues(settingsFields, settings)
		expect(value.yyyy).toBe "wassup?"
		expect(value.zzzz.project).toBe 1234
		expect(value.zzzz.scopeUp).toBe true
		expect(value.zzzz.scopeDown).toBe false



	it 'converts milestone-picker into settings milestone picker', ->
		settingsFields = [
			{ type: 'milestone-picker', name: 'xyzy' }
		]

		expected = [
			{
				xtype: 'rallymilestonecombobox'
				name: 'xyzy'
				label: 'Milestone'
			}
		]

		converted = @xformer.transform(settingsFields)
		expect(converted).toEqual expected



	it 'should convert milestone-picker settings to a nice object', ->
		settingsFields = [
			{ type: 'milestone-picker', name:'zzzz' }
		]

		settings=
			zzzz: '/milestone/1234'

		key = 'zzzz'

		value = @xformer.getValue(settingsFields, settings, key)
		expect(value).toBe 1234

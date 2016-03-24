Ext = window.Ext4 || window.Ext

Ext.require [
	'Rally.apps.chartbuilder.EaselSettingsTransformer',
	'Rally.data.wsapi.Filter'
]

describe 'Rally.apps.chartbuilder.EaselSettingsTransformer', ->

	helpers
		createXformer: ->
			return Ext.create 'Rally.apps.chartbuilder.EaselSettingsTransformer'

	beforeEach ->
		@filter = [
			config: {},
			filter: @stub()
		]
		@xformer = @createXformer()
		@stub(Rally.data.wsapi.Filter, 'or').returns(@filter)

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
				items: [
					{label:'Red', value: 'red'},
					{label:'Blue', value: 'blue'},
					{label:'Black', value: 'black'}
				]
			}
		]

		expected = [
			{
				"xtype":"rallycombobox"
				"hideLabel": false
				"valueField":"value"
				"displayField":"label"
				"label":"Color Fool"
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
			xtype: 'rallymilestonecombobox'
			hideLabel: false
			name: 'xyzy'
			label: 'Milestone'
			autoExpand: true
			selectOnFocus: true
			allowNoEntry: true
			storeConfig:
				remoteFilter: true
				filters: [@filter]
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

	it 'converts state-field-picker into settings milestone picker', ->
		settingsFields = [
			{
				type: 'state-field-picker', name: 'xyz', label: 'State Field', multi: true, fields: [
					{ name: 'name', default: 'alphabet', label: 'State Field Name' },
					{ name: 'values', default: 'a,b,c,d,e,f', label: 'State Field Values' }
				]
			}
		]

		expected = [
			{
				xtype: 'rallychartbuildersettingsstatefieldpicker',
				name: 'xyz'
			}
		]

		converted = @xformer.transform(settingsFields)
		expect(converted).toEqual expected

	it 'should convert state-field-picker settings to a nice object', ->
		settingsFields = [
			{
				type: 'state-field-picker', name: 'xyz', label: 'State Field', multi: true, fields: [
					{ name: 'name', default: 'alphabet', label: 'State Field Name' },
					{ name: 'values', default: 'a,b,c,d,e,f', label: 'State Field Values' }
				]
			}
		]

		settings =
			xyz: '{"name":"n","values":[1,2,3]}'

		expect(@xformer.getValue(settingsFields, settings, 'xyz').name).toEqual 'n'
		expect(@xformer.getValue(settingsFields, settings, 'xyz').values).toEqual [1,2,3]

Ext = window.Ext4 || window.Ext

Ext.require [
	'Rally.apps.chartbuilder.EaselAlmBridge'
]

describe 'Rally.apps.chartbuilder.EaselAlmBridge', ->

	helpers
		getContext: (initialValues) ->
			globalContext = Rally.environment.getContext()

			Ext.create 'Rally.app.Context',
				initialValues:Ext.merge
					project:globalContext.getProject()
					workspace:globalContext.getWorkspace()
					user:globalContext.getUser()
					subscription:globalContext.getSubscription()
					, initialValues

		createBridge: (settings = {}) ->
			context = @getContext()
			app = {
				getContext : -> context
				getSettings : -> settings
			}
			api = Ext.create 'Rally.apps.chartbuilder.EaselAlmBridge',
				chartType: 'xxx'
				app: app
			return api

	beforeEach ->
		@api = @createBridge()

	it 'maintains the reference to the passed in chartType', ->
		expect(@api.getChartType()).toBe "xxx"

	it 'returns the appropriate LBAPI Url from the ALM Bridge', ->
		expect(@api.lbapiBaseUrl()).toBe '/analytics/v2.0'

	it 'returns the appropriate WSAPI Url from the ALM Bridge', ->
		expect(@api.wsapiBaseUrl()).toBe '/webservice/v2.x'

	it 'returns the appropriate workspace from the ALM Bridge', ->
		expect(@api.getWorkspace().ObjectID).toBe Rally.environment.getContext().getWorkspace().ObjectID

	it 'returns the appropriate project from the ALM Bridge', ->
		expect(@api.getProject().ObjectID).toBe Rally.environment.getContext().getProject().ObjectID

	it 'returns project settings', ->
		settings =
			project: 12345
		api = @createBridge(settings)
		api.registerSettingsFields({ type: 'project-picker', name:'project' })
		expect(api.getAppSettings().project).toBe settings.project

	it 'has no default settings by default', ->
		expect(@api.getDefaultSettings()).toEqual {}

	it 'calculates default settings when registered', ->
		@api.registerSettingsFields([
			{type: 'text', name: 'has-default', label: 'Chart Title', default: 'the default value'},
			{type: 'text', name: 'has-no-default', label: 'Chart Sub-Title2'}
		])
		expect(@api.getDefaultSettings()['has-default']).toBe 'the default value'
		expect(@api.getDefaultSettings()['has-no-default']).toBeUndefined()

	it 'picks up default setting for top-level setting when no fields are specified for a multi-field setting', ->
		@api.registerSettingsFields([
			{type: 'text', name: 'top-level-field', label: 'Top Level', multi: true, default: 'z' }
		])
		expect(@api.getDefaultSettings()['sub-field-1']).toBeUndefined()
		expect(@api.getDefaultSettings()['sub-field-2']).toBeUndefined()
		expect(@api.getDefaultSettings()['top-level-field']).toBe 'z'


Ext = window.Ext4 || window.Ext

Ext.require [
	'Rally.apps.chartbuilder.ChartPanelApp'
]

describe 'Rally.apps.chartbuilder.ChartPanelApp', ->

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

		createApp: (config={}, contextValues={}) ->
			context = @getContext()
			@container = Ext.create 'Ext.Container',
				renderTo:'testDiv'

			@app = Ext.create 'Rally.apps.chartbuilder.ChartPanelApp', Ext.merge
				appContainer:
					slug: config.slug || 'theslug'
				context: context
			, config

			@app.getUrlSearchString = -> contextValues.searchString || ''

			@container.add(@app)
			@app

		createAppAndWait: (config={}, contextValues={}) ->
			@createApp(config,contextValues)
			@once condition: => @app.down '#mrcontainer'

		getIFrame : (app) ->
			expect(app).toBeDefined()
			return app.el.dom.firstChild



	it 'sets up the almbridge on the iframe', ->
		@createAppAndWait().then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.almBridge).toBeDefined()

	it 'returns the slug value from getChartType', ->
		@createAppAndWait().then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.almBridge.getChartType()).toBe 'theslug'

	it 'ignores any path information in the slug', ->
		@createAppAndWait({ slug:'xxx/yyy/theslug' }).then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.almBridge.getChartType()).toBe 'theslug'


	it 'returns the appropriate workspace from the ALM Bridge', ->
		@createAppAndWait().then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.almBridge.getWorkspace().ObjectID).toBe Rally.environment.getContext().getWorkspace().ObjectID

	it 'returns the appropriate project from the ALM Bridge', ->
		@createAppAndWait().then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.almBridge.getProject().ObjectID).toBe Rally.environment.getContext().getProject().ObjectID

	describe 'queso url with burroUrl', ->
		oldBurroUrl = window.burroUrl

		beforeEach ->
			window.burroUrl = '/def/leppard'

		afterEach ->
			window.burroUrl = oldBurroUrl

		it 'uses default almchart.html as the iframe source', ->
			@createAppAndWait().then (app) =>
				iframe = @getIFrame(app)
				expect(iframe.src).toContain "/def/leppard/queso/0.3.9/almchart.min.html"

		it 'changes shim location if packtag=false', ->
			@createAppAndWait({}, { searchString : "?packtag=false" }).then (app) =>
				iframe = @getIFrame(app)
				expect(iframe.src).toContain "/def/leppard/queso/0.3.9/almchart.html"

		it 'keeps minified shim location if packtag != false', ->
			@createAppAndWait({}, { searchString : "?packtag=true" }).then (app) =>
				iframe = @getIFrame(app)
				expect(iframe.src).toContain "/def/leppard/queso/0.3.9/almchart.min.html"

		it 'returns default chart version is not specified', ->
			@createAppAndWait({}, { searchString : "" }).then (app) =>
				iframe = @getIFrame(app)
				expect(iframe.src).toContain "/def/leppard/queso/0.3.9/almchart.min.html"

		it 'uses the appropriate version specified', ->
			@createAppAndWait({}, { searchString : "?chartVersion=xxx" }).then (app) =>
				iframe = @getIFrame(app)
				expect(iframe.src).toContain "/def/leppard/queso/xxx/almchart.min.html"


	describe 'help link', ->
		it 'should register a help topic when help is supplied',->
			topic = Rally.util.Help.findTopic({resource:'x'})
			expect(topic).not.toBeDefined()

			app = @createApp({help:'x'})
			topic = Rally.util.Help.findTopic({resource:'x'})
			expect(topic).toBeDefined()

		it 'should add a link to the header when theres help',->
			app = @createApp({help:'x'})
			icon = app.down("helpicon")
			expect(icon).toBeDefined()

		it 'should not add a link to the header when theres no help',->
			app = @createApp()
			icon = app.down("helpicon")
			expect(icon).toBeNull()

	describe '_hasHelp',->
		it 'should return true if config has help',->
			app = @createApp({help:'x'})
			expect(app._hasHelp()).toBe true

		it 'should return false if config does not have a help value',->
			app = @createApp({})
			expect(app._hasHelp()).toBe false

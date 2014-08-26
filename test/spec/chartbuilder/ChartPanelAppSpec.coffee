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

			@app = Ext.create 'Rally.apps.chartbuilder.ChartPanelApp',
				appContainer:
					slug: 'theslug'
				context: context
			, config

			@app.getUrlSearchString = -> contextValues.searchString || ''

			@container.add(@app)
			@once condition: => @app.down '#mrcontainer'

		getIFrame : (app) ->
			expect(app).toBeDefined()
			return app.el.dom.firstChild


	it 'uses default almchart.html as the iframe source', ->
		@createApp().then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.src).toContain "/analytics/chart/latest/almchart.min.html"

	it 'sets up the almbridge on the iframe', ->
		@createApp().then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.almBridge).toBeDefined()

	it 'returns the slug value from getChartType', ->
		@createApp().then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.almBridge.getChartType()).toBe 'theslug'

	it 'returns the appropriate workspace from the ALM Bridge', ->
		@createApp().then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.almBridge.getWorkspace().ObjectID).toBe Rally.environment.getContext().getWorkspace().ObjectID

	it 'returns the appropriate project from the ALM Bridge', ->
		@createApp().then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.almBridge.getProject().ObjectID).toBe Rally.environment.getContext().getProject().ObjectID

	it 'changes shim location if packtag=false', ->
		@createApp({}, { searchString : "?packtag=false" }).then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.src).toContain "/analytics/chart/latest/almchart.html"

	it 'keeps minified shim location if packtag != false', ->
		@createApp({}, { searchString : "?packtag=true" }).then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.src).toContain "/analytics/chart/latest/almchart.min.html"

	it 'returns latest if chart version is not specified', ->
		@createApp({}, { searchString : "" }).then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.src).toContain "/analytics/chart/latest/almchart.min.html"

	it 'uses the appropriate version specified', ->
		@createApp({}, { searchString : "?chartVersion=xxx" }).then (app) =>
			iframe = @getIFrame(app)
			expect(iframe.src).toContain "/analytics/chart/xxx/almchart.min.html"


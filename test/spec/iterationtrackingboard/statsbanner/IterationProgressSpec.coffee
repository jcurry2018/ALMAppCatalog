Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.app.TimeboxScope',
  'Rally.data.wsapi.artifact.Store',
  'Rally.apps.iterationtrackingboard.statsbanner.IterationProgress'
]

describe 'Rally.apps.iterationtrackingboard.statsbanner.IterationProgress', ->

  helpers
    createIterationProgress: () ->
      Ext.create 'Rally.apps.iterationtrackingboard.statsbanner.IterationProgress',
        context: {}
        store: Ext.create('Rally.data.wsapi.artifact.Store')
    createContext: (withRecord = true) ->
      @iterationRecord = @mom.getRecord('iteration', values: { _ref: '/iteration/1' }) if withRecord
      @context =
        getProject: -> Rally.environment.getContext().getProject()
        getTimeboxScope: =>
          Ext.create 'Rally.app.TimeboxScope', record: @iterationRecord, type: 'iteration'

    stubWsapiCalls: ->
      @stories = @mom.getRecords('userstory', {count: 1, values: { Summary: {Task: {Count: 0}, Defects: {Count: 0}} }})

      @ajax.whenQuerying('artifact').respondWith(_.pluck(@stories, 'data'))
      @ajax.whenQuerying('Project').respondWith()

    stubSlmChartsCalls: ->
      projectOid = Rally.environment.getContext().getProject().ObjectID
      cumulativeFlowXMLData = "<chart >\n    <license>E1XXX3MEW9L.HSK5T4Q79KLYCK07EK</license>\n    <axis_category orientation=\"vertical_down\" size='9' color='000000' alpha='75' font='arial' bold='true' skip='0' />\n    <axis_value font=\"arial\" size=\"12\" color='000000'/>\n    <chart_grid_h alpha='20' color='000000' thickness='1' type='solid' />\n    <chart_border color='000000' top_thickness='0' bottom_thickness='0' left_thickness='0' right_thickness='0' />\n    <chart_data>\n            <row>\n                <null/>\n                    <string>Aug-19</string>\n                    <string>Aug-20</string>\n                    <string>Aug-23</string>\n                    <string>Aug-24</string>\n                    <string>Aug-25</string>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>Released</string>\n                <number></number>\n                <number></number>\n                <number></number>\n                <number></number>\n                <number></number>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>Accepted</string>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>2.1</number>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>Completed</string>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>1.1</number>\n                <number>2.0</number>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>In-Progress</string>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>4.0</number>\n                <number>6.45</number>\n                <number>4.0</number>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>Defined</string>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>9.8</number>\n                <number>9.6</number>\n                <number>9.2</number>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>Idea</string>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>0.1</number>\n                <number>0.0</number>\n                <number>0.0</number>\n            </row>\n        </chart_data>\n    <chart_rect x='63' y='40' width='525' height='300' positive_color='D2D8DD' positive_alpha='30' negative_color='D2D8DD' negative_alpha='10' />\n        <chart_type>stacked column</chart_type>\n    <chart_value prefix='' suffix='' decimals='0' separator='' position='cursor' hide_zero='true' as_percentage='false' font='arial' bold='true' size='18' color='ff0000' alpha='100' />\n    <!--<chart_transition type='dissolve' delay='0' duration='.05' order='category' />-->\n    <draw>\n      <text alpha='100' color='454545' bold='true' size='16' x='63' y='10' width='400' height='30' h_align='left' v_align='top'></text>\n        <text alpha='80' color='454545' size=\"12\" x=\"10\" y=\"240.0\" rotation='-90'>Plan Estimate</text>\n        <text alpha='80' color='454545' size=\"12\" x=\"305.5\" y=\"395\">Date</text>\n            <image x=\"566\" y=\"6\" width=\"24\" height=\"24\" url=\"http://localhost:80/slm/images/icon_help.jpg\"></image>\n        <image x=\"542\" y=\"10\" height=\"18\" width=\"20\" url=\"http://localhost:80/slm/images/icon_printer.jpg\"></image>\n    </draw>\n    <axis_value max=\"8\"/>\n    <link>\n        <area alt=\"Print\" x=\"542\" y=\"10\" height=\"18\" width=\"20\" target=\"print\"/>\n\n    </link>\n    <legend_label layout='horizontal' font='arial' bold='true' size='9' color='444466' alpha='90' />\n    <legend_rect margin=\"2\"  x='63' y='425' width='525' height='25'  positive_color='000000' positive_alpha='0'  />\n    <!--<legend_transition type='dissolve' delay='0' duration='1' />-->\n    <series_color>\n            <color>bca3db</color>\n            <color>76c10f</color>\n            <color>f5d100</color>\n            <color>026cfd</color>\n            <color>f8a010</color>\n            <color>8868b0</color>\n        </series_color>\n</chart>";
      burndownXMLData = "<chart >\n    <license>E1XXX3MEW9L.HSK5T4Q79KLYCK07EK</license>\n    <axis_category orientation=\"vertical_down\" size='9' color='000000' alpha='75' font='arial' bold='true' skip='0' />\n    <axis_value font=\"arial\" size=\"12\" color='026cfd'/>\n    <chart_grid_h alpha='20' color='000000' thickness='1' type='solid' />\n    <chart_border color='000000' top_thickness='0' bottom_thickness='0' left_thickness='0' right_thickness='0' />\n    <chart_data>\n            <row>\n                <null/>\n                    <string>Aug-19</string>\n                    <string>Aug-20</string>\n                    <string>Aug-23</string>\n                    <string>Aug-24</string>\n                    <string>Aug-25</string>\n            </row>\n            <row>\n                <string>To-Do</string>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>11.5</number>\n            </row>\n            <row>\n                <string>Accepted</string>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>4.2</number>\n            </row>\n            <row>\n                <string>Ideal Burndown</string>\n                    <number>16.0</number>\n                    <number>12.0</number>\n                    <number>8.0</number>\n                    <number>4.0</number>\n                    <number>0.0</number>\n            </row>\n        </chart_data>\n        <chart_value_text>\n            <row>\n                <null />\n                    <null />\n                    <null />\n                    <null />\n                    <null />\n                    <null />\n            </row>\n            <row>\n                <null />\n                    <number>0 Hours</number>\n                    <number>0 Hours</number>\n                    <number>0 Hours</number>\n                    <number>0 Hours</number>\n                    <number>11.5 Hours</number>\n            </row>\n            <row>\n                <null />\n                    <number>0 Points</number>\n                    <number>0 Points</number>\n                    <number>0 Points</number>\n                    <number>0 Points</number>\n                    <number>2.1 Points</number>\n            </row>\n            <row>\n                <null />\n                    <number>16 Hours</number>\n                    <number>12 Hours</number>\n                    <number>8 Hours</number>\n                    <number>4 Hours</number>\n                    <number>0 Hours</number>\n            </row>\n        </chart_value_text>\n    <chart_rect x='63' y='40' width='525' height='300' positive_color='D2D8DD' positive_alpha='30' negative_color='D2D8DD' negative_alpha='10' />\n    <chart_pref point_shape='circle' fill_shape='true' />\n        <chart_type>column</chart_type>\n    <chart_type>\n            <string>column</string>\n            <string>column</string>\n            <string>line</string>\n        </chart_type>\n    <chart_value prefix='' suffix='' decimals='0' separator='' position='cursor' hide_zero='true' as_percentage='false' font='arial' bold='true' size='18' color='ff0000' alpha='100' />\n    <!--<chart_transition type='dissolve' delay='0' duration='.05' order='category' />-->\n    <draw>\n <text alpha='100' color='454545' bold='true' size='16' x='63' y='10' width='400' height='30' h_align='left' v_align='top'>Iteration Burn Down</text>\n        <text alpha='80' color='454545' size=\"12\" x=\"10\" y=\"240.0\" rotation='-90'>To Do (Hours)</text>\n        <text alpha='80' color='454545' size=\"12\" x=\"305.5\" y=\"395\">Date</text>\n        <image x=\"566\" y=\"6\" width=\"24\" height=\"24\" url=\"http://localhost:80/slm/images/icon_help.jpg\"></image>\n        <image x=\"542\" y=\"10\" height=\"18\" width=\"20\" url=\"http://localhost:80/slm/images/icon_printer.jpg\"></image>\n                <text x=\"590\" y=\"333\" orientation=\"vertical_down\" size='12' color='76c10f' font='arial' bold='true'>0</text>\n                <text x=\"590\" y=\"258\" orientation=\"vertical_down\" size='12' color='76c10f' font='arial' bold='true'>2</text>\n                <text x=\"590\" y=\"183\" orientation=\"vertical_down\" size='12' color='76c10f' font='arial' bold='true'>4</text>\n                <text x=\"590\" y=\"108\" orientation=\"vertical_down\" size='12' color='76c10f' font='arial' bold='true'>6</text>\n                <text x=\"590\" y=\"33\" orientation=\"vertical_down\" size='12' color='76c10f' font='arial' bold='true'>8</text>\n            <text alpha='80' color='454545' size=\"12\" x=\"643\" y=\"120.0\" rotation='90'>Accepted (Points)</text>\n    </draw>\n    <axis_value max=\"16\"/>\n    <link>\n        <area alt=\"Print\" x=\"542\" y=\"10\" height=\"18\" width=\"20\" target=\"print\"/>\n\n    </link>\n    <legend_label layout='horizontal' font='arial' bold='true' size='9' color='444466' alpha='90' />\n    <legend_rect margin=\"2\"  x='63' y='425' width='525' height='25'  positive_color='000000' positive_alpha='0'  />\n    <!--<legend_transition type='dissolve' delay='0' duration='1' />-->\n    <series_color>\n            <color>026cfd</color>\n            <color>76c10f</color>\n            <color>00326f</color>\n    </series_color>\n</chart>";
      this.ajax.whenReadingEndpoint("/slm/charts/itsc.sp?sid=&iterationOid=1&cpoid=" + projectOid).respondWithHtml(burndownXMLData, {
        url: '/slm/charts/itsc.sp',
        method: 'GET'
      });
      this.ajax.whenReadingEndpoint("/slm/charts/icfc.sp?sid=&iterationOid=1&bigChart=true&cpoid=" + projectOid).respondWithHtml(cumulativeFlowXMLData, {
        url: '/slm/charts/icfc.sp',
        method: 'GET'
      });

    createFullIterationProgress: (withRecord = true, config = {}) ->
      @stubWsapiCalls()
      @createContext(withRecord)
      @createStore()
      @stubSlmChartsCalls()

      afterRenderSpy = @spy()

      @pane = Ext.create('Rally.apps.iterationtrackingboard.statsbanner.IterationProgress', Ext.Object.merge({
        context: @context,
        store: @store,
        renderTo: 'testDiv'
        listeners:
          afterrender: afterRenderSpy
      }, config))

      @waitForCallback(afterRenderSpy)

    createStore: () ->
      @store = Ext.create 'Rally.data.wsapi.artifact.Store', {
        models: ['UserStory', 'Defect', 'DefectSuite'],
        fetch: ['Defects:summary[State;ScheduleState+Blocked]', 'PlanEstimate', 'Requirement', 'FormattedID', 'Name', 'Blocked', 'BlockedReason',
                        'ScheduleState', 'State', 'Tasks:summary[State;State+Blocked]', 'TestCases'],
        limit: Infinity,
        autoLoad: true
      }

    waitForChart: ->
      once(
        condition: -> Ext.DomQuery.select('svg').length == 3
        describe: 'waiting for svg elements'
      )

  afterEach ->
    Rally.test.destroyComponentsOfQuery [
      'statsbanneriterationprogress'
      'rallycarousel'
      'statsbannerpiechart'
      'statsbannerminimalpiechart'
      'statsbannerburndownchart'
      'statsbannercumulativeflowchart'
    ]

  describe 'chart settings', ->

    it 'should default to zero', ->
      iterationProgress = @createIterationProgress()
      expect(iterationProgress.currentChartDisplayed).toBe(0)
      expect(iterationProgress.getState().currentChartDisplayed).toBe(0)

    it 'should apply the state', ->
      iterationProgress = @createIterationProgress()
      iterationProgress.applyState(currentChartDisplayed: 2)

      expect(iterationProgress.currentChartDisplayed).toBe(2)
      expect(iterationProgress.getState().currentChartDisplayed).toBe(2)

    it 'should not set the current chart to a number higher that the number of items in the carousel', ->
      iterationProgress = @createIterationProgress()

      totalItems = iterationProgress.carouselItems.length

      iterationProgress.applyState(currentChartDisplayed: totalItems+1)
      expect(iterationProgress.currentChartDisplayed).toBe(0)

  describe 'carousel', ->

    it 'loads items on data load', ->
      readySpy = @spy()
      @createFullIterationProgress(true, {listeners: ready: readySpy}).then =>
        @waitForCallback(readySpy).then ->
          expect(Ext.ComponentQuery.query('rallycarousel').length).toBe 1
          expect(Ext.ComponentQuery.query('statsbannerminimalpiechart').length).toBe 1
          expect(Ext.ComponentQuery.query('statsbannerburndownchart').length).toBe 1
          expect(Ext.ComponentQuery.query('statsbannercumulativeflowchart').length).toBe 1

    it 'does not load when no data records are loaded', ->
      @createFullIterationProgress(false).then ->
        expect(Ext.DomQuery.select('.stat-carousel')[0].textContent).toBe 'no iteration data'

    it 'creates a new carousel if data has changed when in collapsed mode', ->
      @createFullIterationProgress().then =>
        @store.add @mom.getRecord('userstory')
        @pane.collapse()
        createCarouselSpy = @spy @pane, 'createCarousel'
        @store.add @mom.getRecord('userstory')
        @pane.expand()
        expect(createCarouselSpy.callCount).toBe 1

    it 'does not create a new carousel if data has not changed when panel is expanded', ->
      @createFullIterationProgress().then =>
        @store.add @mom.getRecord('userstory')
        @pane.collapse()
        createCarouselSpy = @spy @pane, 'createCarousel'
        @pane.expand()
        expect(createCarouselSpy.callCount).toBe 0

    it 'updates title when carousel current item is set', ->
      readySpy = @spy()
      @createFullIterationProgress(true, {listeners: ready: readySpy}).then =>
        @waitForCallback(readySpy).then =>
          title = @pane.carousel.getCurrentItem().displayTitle

          expect(@pane.getEl().down('.expanded-widget .stat-title').dom.innerHTML).toContain title
          expect(@pane.getEl().down('.collapsed-widget .stat-title').dom.innerHTML).toContain title

    it 'updates title when carousel moves', ->
      readySpy = @spy()
      @createFullIterationProgress(true, {listeners: ready: readySpy}).then =>
        @waitForCallback(readySpy).then =>
          title = @pane.carousel.getCurrentItem().displayTitle
          @pane.carousel.scrollForward()
          nextTitle = @pane.carousel.getCurrentItem().displayTitle

          expect(title).not.toBe nextTitle
          expect(@pane.getEl().down('.expanded-widget .stat-title').dom.innerHTML).toContain nextTitle
          expect(@pane.getEl().down('.collapsed-widget .stat-title').dom.innerHTML).toContain nextTitle

  describe 'events', ->
    describe 'ready', ->
      it 'should fire ready when all of the charts are ready', ->
        readySpy = @spy()
        @createFullIterationProgress(true, {listeners: ready: readySpy}).then =>
          @waitForCallback(readySpy)

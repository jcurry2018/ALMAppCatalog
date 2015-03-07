Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.app.TimeboxScope',
  'Rally.data.wsapi.artifact.Store'
]

describe 'Rally.apps.iterationtrackingboard.statsbanner.iterationprogresscharts.BurndownChart', ->

  helpers
    createContext: (withRecord = true) ->
      @iterationRecord = @mom.getRecord('iteration', values: { _ref: '/iteration/1' }) if withRecord
      @context =
        getProject: -> Rally.environment.getContext().getProject()
        getTimeboxScope: =>
          Ext.create 'Rally.app.TimeboxScope', record: @iterationRecord

    stubSlmChartsCalls: ->
      projectOid = Rally.environment.getContext().getProject().ObjectID
      burndownXMLData = "<chart >\n    <license>E1XXX3MEW9L.HSK5T4Q79KLYCK07EK</license>\n    <axis_category orientation=\"vertical_down\" size='9' color='000000' alpha='75' font='arial' bold='true' skip='0' />\n    <axis_value font=\"arial\" size=\"12\" color='026cfd'/>\n    <chart_grid_h alpha='20' color='000000' thickness='1' type='solid' />\n    <chart_border color='000000' top_thickness='0' bottom_thickness='0' left_thickness='0' right_thickness='0' />\n    <chart_data>\n            <row>\n                <null/>\n                    <string>Aug-19</string>\n                    <string>Aug-20</string>\n                    <string>Aug-23</string>\n                    <string>Aug-24</string>\n                    <string>Aug-25</string>\n            </row>\n            <row>\n                <string>To-Do</string>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>11.5</number>\n            </row>\n            <row>\n                <string>Accepted</string>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>0.0</number>\n                    <number>4.2</number>\n            </row>\n            <row>\n                <string>Ideal Burndown</string>\n                    <number>16.0</number>\n                    <number>12.0</number>\n                    <number>8.0</number>\n                    <number>4.0</number>\n                    <number>0.0</number>\n            </row>\n        </chart_data>\n        <chart_value_text>\n            <row>\n                <null />\n                    <null />\n                    <null />\n                    <null />\n                    <null />\n                    <null />\n            </row>\n            <row>\n                <null />\n                    <number>0 Hours</number>\n                    <number>0 Hours</number>\n                    <number>0 Hours</number>\n                    <number>0 Hours</number>\n                    <number>11.5 Hours</number>\n            </row>\n            <row>\n                <null />\n                    <number>0 Points</number>\n                    <number>0 Points</number>\n                    <number>0 Points</number>\n                    <number>0 Points</number>\n                    <number>2.1 Points</number>\n            </row>\n            <row>\n                <null />\n                    <number>16 Hours</number>\n                    <number>12 Hours</number>\n                    <number>8 Hours</number>\n                    <number>4 Hours</number>\n                    <number>0 Hours</number>\n            </row>\n        </chart_value_text>\n    <chart_rect x='63' y='40' width='525' height='300' positive_color='D2D8DD' positive_alpha='30' negative_color='D2D8DD' negative_alpha='10' />\n    <chart_pref point_shape='circle' fill_shape='true' />\n        <chart_type>column</chart_type>\n    <chart_type>\n            <string>column</string>\n            <string>column</string>\n            <string>line</string>\n        </chart_type>\n    <chart_value prefix='' suffix='' decimals='0' separator='' position='cursor' hide_zero='true' as_percentage='false' font='arial' bold='true' size='18' color='ff0000' alpha='100' />\n    <!--<chart_transition type='dissolve' delay='0' duration='.05' order='category' />-->\n    <draw>\n <text alpha='100' color='454545' bold='true' size='16' x='63' y='10' width='400' height='30' h_align='left' v_align='top'>Iteration Burn Down</text>\n        <text alpha='80' color='454545' size=\"12\" x=\"10\" y=\"240.0\" rotation='-90'>To Do (Hours)</text>\n        <text alpha='80' color='454545' size=\"12\" x=\"305.5\" y=\"395\">Date</text>\n        <image x=\"566\" y=\"6\" width=\"24\" height=\"24\" url=\"http://localhost:80/slm/images/icon_help.jpg\"></image>\n        <image x=\"542\" y=\"10\" height=\"18\" width=\"20\" url=\"http://localhost:80/slm/images/icon_printer.jpg\"></image>\n                <text x=\"590\" y=\"333\" orientation=\"vertical_down\" size='12' color='76c10f' font='arial' bold='true'>0</text>\n                <text x=\"590\" y=\"258\" orientation=\"vertical_down\" size='12' color='76c10f' font='arial' bold='true'>2</text>\n                <text x=\"590\" y=\"183\" orientation=\"vertical_down\" size='12' color='76c10f' font='arial' bold='true'>4</text>\n                <text x=\"590\" y=\"108\" orientation=\"vertical_down\" size='12' color='76c10f' font='arial' bold='true'>6</text>\n                <text x=\"590\" y=\"33\" orientation=\"vertical_down\" size='12' color='76c10f' font='arial' bold='true'>8</text>\n            <text alpha='80' color='454545' size=\"12\" x=\"643\" y=\"120.0\" rotation='90'>Accepted (Points)</text>\n    </draw>\n    <axis_value max=\"16\"/>\n    <link>\n        <area alt=\"Print\" x=\"542\" y=\"10\" height=\"18\" width=\"20\" target=\"print\"/>\n\n    </link>\n    <legend_label layout='horizontal' font='arial' bold='true' size='9' color='444466' alpha='90' />\n    <legend_rect margin=\"2\"  x='63' y='425' width='525' height='25'  positive_color='000000' positive_alpha='0'  />\n    <!--<legend_transition type='dissolve' delay='0' duration='1' />-->\n    <series_color>\n            <color>026cfd</color>\n            <color>76c10f</color>\n            <color>00326f</color>\n    </series_color>\n</chart>";

      @ajaxStub = this.ajax.whenReadingEndpoint("/slm/charts/itsc.sp?sid=&iterationOid=1&cpoid=" + projectOid).respondWithHtml(burndownXMLData, {
        url: '/slm/charts/itsc.sp',
        method: 'GET'
      });

    createStore: () ->
      @store = Ext.create 'Rally.data.wsapi.artifact.Store'

    createChart: (config) ->
      @createContext()
      @createStore()
      @stubSlmChartsCalls()

      chartConfig = Ext.Object.merge({
        context: @context,
        store: @store,
        renderTo: 'testDiv'
      }, config)

      burnChart = Ext.create('Rally.apps.iterationtrackingboard.statsbanner.iterationprogresscharts.BurndownChart', chartConfig)
      @waitForComponentReady(burnChart)

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'statsbannerburndownchart'

  it 'should load a Burndown Chart with data from XML', ->
    @createChart().then (burnChart) ->

      burndownData = burnChart.chartComponentConfig.chartData
      expect(burndownData.series.length).toBe 3
      expect(burndownData.series[0].data[0]).toBe 0
      expect(burndownData.series[0].data[4]).toBe 11.5
      expect(burndownData.series[0].name).toBe "To Do"
      expect(burndownData.series[1].data[0]).toBe 16
      expect(burndownData.series[1].data[4]).toBe 0
      expect(burndownData.series[1].name).toBe "Ideal"
      expect(burndownData.series[2].data[0]).toBe 0
      expect(burndownData.series[2].data[4]).toBe 2.1
      expect(burndownData.series[2].name).toBe "Accepted"
      expect(burndownData.categories.length).toBe 5
      expect(burndownData.categories[0]).toBe "Aug-19"
      expect(burndownData.categories[4]).toBe "Aug-25"

  it 'should request data when constructed', ->
    @createChart().then (burnChart) =>
      expect(@ajaxStub).toHaveBeenCalledOnce()

  describe 'minimalMode: true', ->
    it 'should not have tooltips, legend or labels', ->
      @createChart({
        minimalMode: true
      }).then (burnChart) ->
        chartConfig = burnChart.chartComponentConfig.chartConfig

        expect(chartConfig.tooltip).toBeDefined()
        expect(chartConfig.tooltip.formatter).toBeAFunction()
        expect(chartConfig.tooltip.formatter()).toBeFalsy()
        expect(chartConfig.legend.enabled).toBe false
        expect(chartConfig.xAxis.labels.enabled).toBe false
        expect(chartConfig.yAxis[0].labels.enabled).toBe false

  describe 'minimalMode: false', ->
    it 'should have tooltips, legend and labels', ->
      @createChart({
        minimalMode: false
      }).then (burnChart) ->
        chartConfig = burnChart.chartComponentConfig.chartConfig

        expect(chartConfig.tooltip).toBeUndefined()
        expect(chartConfig.legend.enabled).toBe true
        expect(chartConfig.xAxis.labels).toBeUndefined()
        expect(chartConfig.yAxis[0].labels.enabled).toBeUndefined()

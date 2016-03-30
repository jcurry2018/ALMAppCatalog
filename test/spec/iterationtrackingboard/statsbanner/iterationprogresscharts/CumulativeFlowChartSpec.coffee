Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.app.TimeboxScope',
  'Rally.data.wsapi.artifact.Store'
]

describe 'Rally.apps.iterationtrackingboard.statsbanner.iterationprogresscharts.CumulativeFlowChart', ->

  helpers
    createContext: (withRecord = true) ->
      @iterationRecord = @mom.getRecord('iteration', values: { _ref: '/iteration/1' }) if withRecord
      @context =
        getProject: -> Rally.environment.getContext().getProject()
        getTimeboxScope: =>
          Ext.create 'Rally.app.TimeboxScope', record: @iterationRecord

    stubSlmChartsCalls: ->
      projectOid = Rally.environment.getContext().getProject().ObjectID
      cumulativeFlowXMLData = "<chart >\n    <license>E1XXX3MEW9L.HSK5T4Q79KLYCK07EK</license>\n    <axis_category orientation=\"vertical_down\" size='9' color='000000' alpha='75' font='arial' bold='true' skip='0' />\n    <axis_value font=\"arial\" size=\"12\" color='000000'/>\n    <chart_grid_h alpha='20' color='000000' thickness='1' type='solid' />\n    <chart_border color='000000' top_thickness='0' bottom_thickness='0' left_thickness='0' right_thickness='0' />\n    <chart_data>\n            <row>\n                <null/>\n                    <string>Aug-19</string>\n                    <string>Aug-20</string>\n                    <string>Aug-23</string>\n                    <string>Aug-24</string>\n                    <string>Aug-25</string>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>Released</string>\n                <number></number>\n                <number></number>\n                <number></number>\n                <number></number>\n                <number></number>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>Accepted</string>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>2.1</number>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>Completed</string>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>1.1</number>\n                <number>2.0</number>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>In-Progress</string>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>4.0</number>\n                <number>6.45</number>\n                <number>4.0</number>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>Defined</string>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>9.8</number>\n                <number>9.6</number>\n                <number>9.2</number>\n            </row>\n            <row>\n                <!-- just an arbitrary cut off point for state names based on the fact that there can be six of them and they won't fit on the chart -->\n                <string>Idea</string>\n                <number>0.0</number>\n                <number>0.0</number>\n                <number>0.1</number>\n                <number>0.0</number>\n                <number>0.0</number>\n            </row>\n        </chart_data>\n    <chart_rect x='63' y='40' width='525' height='300' positive_color='D2D8DD' positive_alpha='30' negative_color='D2D8DD' negative_alpha='10' />\n        <chart_type>stacked column</chart_type>\n    <chart_value prefix='' suffix='' decimals='0' separator='' position='cursor' hide_zero='true' as_percentage='false' font='arial' bold='true' size='18' color='ff0000' alpha='100' />\n    <!--<chart_transition type='dissolve' delay='0' duration='.05' order='category' />-->\n    <draw>\n      <text alpha='100' color='454545' bold='true' size='16' x='63' y='10' width='400' height='30' h_align='left' v_align='top'></text>\n        <text alpha='80' color='454545' size=\"12\" x=\"10\" y=\"240.0\" rotation='-90'>Plan Estimate</text>\n        <text alpha='80' color='454545' size=\"12\" x=\"305.5\" y=\"395\">Date</text>\n            <image x=\"566\" y=\"6\" width=\"24\" height=\"24\" url=\"http://localhost:80/slm/images/icon_help.jpg\"></image>\n        <image x=\"542\" y=\"10\" height=\"18\" width=\"20\" url=\"http://localhost:80/slm/images/icon_printer.jpg\"></image>\n    </draw>\n    <axis_value max=\"8\"/>\n    <link>\n        <area alt=\"Print\" x=\"542\" y=\"10\" height=\"18\" width=\"20\" target=\"print\"/>\n\n    </link>\n    <legend_label layout='horizontal' font='arial' bold='true' size='9' color='444466' alpha='90' />\n    <legend_rect margin=\"2\"  x='63' y='425' width='525' height='25'  positive_color='000000' positive_alpha='0'  />\n    <!--<legend_transition type='dissolve' delay='0' duration='1' />-->\n    <series_color>\n            <color>bca3db</color>\n            <color>76c10f</color>\n            <color>f5d100</color>\n            <color>026cfd</color>\n            <color>f8a010</color>\n            <color>8868b0</color>\n        </series_color>\n</chart>";

      @ajaxStub = this.ajax.whenReadingEndpoint("/slm/charts/icfc.sp?sid=&iterationOid=1&bigChart=true&cpoid=" + projectOid).respondWithHtml(cumulativeFlowXMLData, {
        url: '/slm/charts/icfc.sp',
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

      cumFlowChart = Ext.create('Rally.apps.iterationtrackingboard.statsbanner.iterationprogresscharts.CumulativeFlowChart', chartConfig)
      @waitForComponentReady(cumFlowChart)

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'statsbannercumulativeflowchart'

  describe 'CumulativeFlowChart', ->
    it 'should load a Cumulative Flow Chart with data from XML', ->
      @createChart().then (cumFlowChart) ->
        expect(Ext.ComponentQuery.query('statsbannercumulativeflowchart').length).toBe 1

        chartConfig = cumFlowChart.chartComponentConfig

        data = chartConfig.chartData
        expect(data.series.length).toBe 6
        expect(data.series[0].data[0]).toBe 0
        expect(data.series[0].data[4]).toBe 0
        expect(data.series[0].name).toBe "Idea"
        expect(data.series[1].data[0]).toBe 0
        expect(data.series[1].data[4]).toBe 9.2
        expect(data.series[1].name).toBe "Defined"
        expect(data.series[2].data[0]).toBe 0
        expect(data.series[2].data[4]).toBe 4
        expect(data.series[2].name).toBe "In-Progress"
        expect(data.series[3].data[0]).toBe 0
        expect(data.series[3].data[4]).toBe 2
        expect(data.series[3].name).toBe "Completed"
        expect(data.series[4].data[0]).toBe 0
        expect(data.series[4].data[4]).toBe 2.1
        expect(data.series[4].name).toBe "Accepted"
        expect(data.series[5].data[0]).toBe 0
        expect(data.series[5].data[4]).toBe 0
        expect(data.series[5].name).toBe "Released"
        expect(data.categories.length).toBe 5
        expect(data.categories[0]).toBe "Aug-19"
        expect(data.categories[4]).toBe "Aug-25"

    it 'should request data when constructed', ->
      @createChart().then () =>
        expect(@ajaxStub).toHaveBeenCalledOnce()

  describe 'minimalMode: true', ->
    it 'should not have tooltips, legend or labels', ->
      @createChart({
        minimalMode: true
      }).then (cumFlowChart) ->
        chartConfig = cumFlowChart.chartComponentConfig.chartConfig

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
      }).then (cumFlowChart) ->
        chartConfig = cumFlowChart.chartComponentConfig.chartConfig

        expect(chartConfig.tooltip).toBeUndefined()
        expect(chartConfig.legend.enabled).toBe true
        expect(chartConfig.xAxis.labels).toBeUndefined()
        expect(chartConfig.yAxis[0].labels.enabled).toBeUndefined()

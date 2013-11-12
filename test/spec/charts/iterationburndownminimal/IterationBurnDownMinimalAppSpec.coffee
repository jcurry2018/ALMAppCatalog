Ext = window.Ext4 || window.Ext

describe 'Rally.apps.charts.iterationburndownminimal.IterationBurnDownMinimalApp', ->
  helpers
    getContext: (initialValues) ->
      globalContext = Rally.environment.getContext()

      Ext.create 'Rally.app.Context',
        initialValues: Ext.merge(
          project: globalContext.getProject()
          workspace: globalContext.getWorkspace()
          user: globalContext.getUser()
          timebox: @_createIterationRecord()
          subscription: globalContext.getSubscription()
        , initialValues)

    _createIterationRecord: (data={}) ->
      IterationModel = Rally.test.mock.data.WsapiModelFactory.getIterationModel()
      Ext.create(IterationModel, Ext.apply(
        _ref: '/iteration/1',
        Name: 'Iteration 1',
        StartDate: '2013-01-01',
        EndDate: '2013-01-15'
      , data))

  itscData = """
         <chart >
             <license>E1XXX3MEW9L.HSK5T4Q79KLYCK07EK</license>
             <axis_category orientation="vertical_down" size='9' color='000000' alpha='75' font='arial' bold='true' skip='0' />
             <axis_value font="arial" size="12" color='026cfd'/>
             <chart_grid_h alpha='20' color='000000' thickness='1' type='solid' />
             <chart_border color='000000' top_thickness='0' bottom_thickness='0' left_thickness='0' right_thickness='0' />
             <chart_data>
                     <row>
                         <null/>
                             <string>Aug-19</string>
                             <string>Aug-20</string>
                             <string>Aug-23</string>
                             <string>Aug-24</string>
                             <string>Aug-25</string>
                     </row>
                     <row>
                         <string>To-Do</string>
                             <number>0.0</number>
                             <number>0.0</number>
                             <number>0.0</number>
                             <number>0.0</number>
                             <number>11.5</number>
                     </row>
                     <row>
                         <string>Accepted</string>
                             <number>0.0</number>
                             <number>0.0</number>
                             <number>0.0</number>
                             <number>0.0</number>
                             <number>4.2</number>
                     </row>
                     <row>
                         <string>Ideal Burndown</string>
                             <number>16.0</number>
                             <number>12.0</number>
                             <number>8.0</number>
                             <number>4.0</number>
                             <number>0.0</number>
                     </row>
                 </chart_data>
                 <chart_value_text>
                     <row>
                         <null />
                             <null />
                             <null />
                             <null />
                             <null />
                             <null />
                     </row>
                     <row>
                         <null />
                             <number>0 Hours</number>
                             <number>0 Hours</number>
                             <number>0 Hours</number>
                             <number>0 Hours</number>
                             <number>11.5 Hours</number>
                     </row>
                     <row>
                         <null />
                             <number>0 Points</number>
                             <number>0 Points</number>
                             <number>0 Points</number>
                             <number>0 Points</number>
                             <number>2.1 Points</number>
                     </row>
                     <row>
                         <null />
                             <number>16 Hours</number>
                             <number>12 Hours</number>
                             <number>8 Hours</number>
                             <number>4 Hours</number>
                             <number>0 Hours</number>
                     </row>
                 </chart_value_text>
             <chart_rect x='63' y='40' width='525' height='300' positive_color='D2D8DD' positive_alpha='30' negative_color='D2D8DD' negative_alpha='10' />
             <chart_pref point_shape='circle' fill_shape='true' />
                 <chart_type>column</chart_type>
             <chart_type>
                     <string>column</string>
                     <string>column</string>
                     <string>line</string>
                 </chart_type>
             <chart_value prefix='' suffix='' decimals='0' separator='' position='cursor' hide_zero='true' as_percentage='false' font='arial' bold='true' size='18' color='ff0000' alpha='100' />
             <!--<chart_transition type='dissolve' delay='0' duration='.05' order='category' />-->
             <draw>
         	<text alpha='100' color='454545' bold='true' size='16' x='63' y='10' width='400' height='30' h_align='left' v_align='top'>Iteration Burn Down</text>
                 <text alpha='80' color='454545' size="12" x="10" y="240.0" rotation='-90'>To Do (Hours)</text>
                 <text alpha='80' color='454545' size="12" x="305.5" y="395">Date</text>
                 <image x="566" y="6" width="24" height="24" url="http://localhost:80/slm/images/icon_help.jpg"></image>
                 <image x="542" y="10" height="18" width="20" url="http://localhost:80/slm/images/icon_printer.jpg"></image>
                         <text x="590" y="333" orientation="vertical_down" size='12' color='76c10f' font='arial' bold='true'>0</text>
                         <text x="590" y="258" orientation="vertical_down" size='12' color='76c10f' font='arial' bold='true'>2</text>
                         <text x="590" y="183" orientation="vertical_down" size='12' color='76c10f' font='arial' bold='true'>4</text>
                         <text x="590" y="108" orientation="vertical_down" size='12' color='76c10f' font='arial' bold='true'>6</text>
                         <text x="590" y="33" orientation="vertical_down" size='12' color='76c10f' font='arial' bold='true'>8</text>
                     <text alpha='80' color='454545' size="12" x="643" y="120.0" rotation='90'>Accepted (Points)</text>
             </draw>
             <axis_value max="16"/>
             <link>
                 <area alt="Print" x="542" y="10" height="18" width="20" target="print"/>

             </link>
             <legend_label layout='horizontal' font='arial' bold='true' size='9' color='444466' alpha='90' />
             <legend_rect margin="2"  x='63' y='425' width='525' height='25'  positive_color='000000' positive_alpha='0'  />
             <!--<legend_transition type='dissolve' delay='0' duration='1' />-->
             <series_color>
                     <color>026cfd</color>
                     <color>76c10f</color>
                     <color>00326f</color>
             </series_color>
         </chart>
      """
  it 'creates expected chart from itsc endpoint xml data', ->

    itscReadRequest = @ajax.whenReadingEndpoint("/slm/charts/itsc.sp?sid=&iterationOid=1&cpoid=" + this.getContext().getProject().ObjectID).respondWithHtml itscData, { url: '/slm/charts/itsc.sp', method: 'GET' }

    addSpy = @spy()
    app = Ext.create 'Rally.apps.charts.iterationburndownminimal.IterationBurnDownMinimalApp',
      context: @getContext()
      renderTo: 'testDiv'
      listeners:
        add: addSpy

    @waitForCallback(itscReadRequest).then =>
      burndown = _.where(_.map(addSpy.args, (arg) -> arg[1]), xtype: 'rallychart')[0]
      burndownData = burndown.chartData

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

      chartCount = _.where(_.map(addSpy.args, (arg) -> arg[1]), xtype: 'rallychart').length
      expect(chartCount).toBe 1

      expect(burndown.chartConfig.legend.enabled).toBe true

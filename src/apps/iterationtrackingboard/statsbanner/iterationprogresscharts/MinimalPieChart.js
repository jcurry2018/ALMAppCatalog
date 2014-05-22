(function(){
    var Ext = window.Ext4 || window.Ext;

    Ext.define("Rally.apps.iterationtrackingboard.statsbanner.iterationprogresscharts.MinimalPieChart", {
        alias: "widget.statsbannerminimalpiechart",
        extend: "Rally.apps.iterationtrackingboard.statsbanner.iterationprogresscharts.PieChart",

        _loadArtifacts: function() {
            this._chartData = [];
            this._childChartData = [];
            this._createDataPointsFromSummary();
        },

        _createDataPointsFromSummary: function() {
            _.each(this.store.getRange(), function(record){
                var summary = record.get('Summary');
                var totalChildItems = 0;
                var planEstimate = record.get('PlanEstimate') || 1;
                var nullPointString = 'No tasks or defects.';
                var testCases = record.get('TestCases');
                var keys, state, scheduleState, blocked, count;

                totalChildItems += summary.Defects ? summary.Defects.Count : 0;
                totalChildItems += summary.Tasks ? summary.Tasks.Count : 0;
                totalChildItems += testCases ? testCases.Count : 0;

                var pointSizeForChildren = (planEstimate / totalChildItems) || 1;

                this._addPointForTopLevelItem(record, totalChildItems);

                if (totalChildItems === 0) {
                    this._childChartData.push({
                        name: nullPointString,
                        y: planEstimate,
                        color: '#FFF',
                        rallyName: null,
                        status: '',
                        blocked: false,
                        blockedReason: '',
                        hasChildren: false,
                        relatedCount: 0,
                        ref: null,
                        parentFormattedID: null
                    });
                }
                if (summary.Tasks && summary.Tasks.Count){
                    keys = _.keys(summary.Tasks['state+blocked']);
                    _.each(keys, function(key) {
                        state = key.split('+');
                        scheduleState =  state[0];
                        blocked = state[1] === 'true';
                        count = summary.Tasks['state+blocked'][key];
                        _.each(_.range(0, count), function(point) {
                            this._addPointForChildItem(record.get('FormattedID'), pointSizeForChildren, scheduleState, blocked);
                        }, this);
                    }, this);
                }
                if (summary.Defects && summary.Defects.Count){
                    keys = _.keys(summary.Defects['schedulestate+blocked']);
                    _.each(keys, function(key) {
                        state = key.split('+');
                        scheduleState =  state[0];
                        blocked = state[1] === 'true';
                        count = summary.Defects['schedulestate+blocked'][key];
                        _.each(_.range(0, count), function(point) {
                            this._addPointForChildItem(record.get('FormattedID'), pointSizeForChildren, scheduleState, blocked);
                        }, this);
                    }, this);
                }
                if (testCases && testCases.Count){
                    _.each(_.range(0,testCases.Count), function(point){
                        this._addPointForChildItem(record.get('FormattedID'), pointSizeForChildren, record.get('ScheduleState'), record.get('Blocked'));
                    }, this);
                }
            }, this);

            var chart = this._createChartConfig();
            this.add(chart);

        },

        _onAllDataLoaded: function() {
            _.each(this.store.getRange(), function(record) {
                var defects = record.get('Defects');
                var defectCount = (defects && defects.Count) || 0;
                var tasks = record.get('Tasks');
                var taskCount = (tasks && tasks.Count) || 0;
                var testCases =  record.get('TestCases');
                var testCaseCount = (testCases && testCases.Count) || 0;
                var relatedCount = taskCount + defectCount + testCaseCount;
                var planEstimate = record.get('PlanEstimate') || 1;
                var pointSizeForChildren = (planEstimate / relatedCount) || 1;
                var nullPointString = 'No tasks or defects.';

                this._addPointForTopLevelItem(record, relatedCount);

                if (relatedCount === 0) {
                    this._childChartData.push({
                        name: nullPointString,
                        y: planEstimate,
                        color: '#FFF',
                        rallyName: null,
                        status: '',
                        blocked: false,
                        blockedReason: '',
                        hasChildren: false,
                        relatedCount: 0,
                        ref: null,
                        parentFormattedID: null
                    });
                } else {
                    if (defects && defects.Results) {
                        _.each(defects.Results, function(defect) {
                            this._addPointForChildItem(defect, record.get('FormattedID'), pointSizeForChildren);
                        }, this);
                    }

                    if (tasks && tasks.Results) {
                        _.each(tasks.Results, function(task) {
                            this._addPointForChildItem(task, record.get('FormattedID'), pointSizeForChildren);
                        }, this);
                    }

                    if (testCases && testCases.Results) {
                        _.each(testCases.Results, function(testCase) {
                            this._addPointForChildItem(testCase, record.get('FormattedID'), pointSizeForChildren, record.get('ScheduleState'), record.get('Blocked'));
                        }, this);
                    }
                }
            }, this);

            var chart = this._createChartConfig();
            this.add(chart);

            this.recordLoadEnd();
        },

         _createChartConfig: function(overrides) {
            var clickChartHandler = _.isFunction(this.clickHandler) ? this.clickHandler : Ext.emptyFn;
            var height = this.height;
            return Ext.Object.merge({
                xtype: 'rallychart',
                loadMask: false,
                updateAfterRender: Ext.bind(this._onLoad, this),

                chartData: {
                    series: [
                        {
                            type:'pie',
                            name: 'Parents',
                            data: this._chartData,
                            size: height,
                            allowPointSelect: false,
                            dataLabels: {
                                enabled: false
                            }
                        },
                        {
                            type:'pie',
                            name: 'Children',
                            data: this._childChartData,
                            size: height,
                            innerSize: 0.8 * height,
                            allowPointSelect: false,
                            dataLabels: { enabled: false }
                        }
                    ]
                },

                chartConfig: {
                    chart: {
                        type: 'pie',
                        height: height,
                        width: this.width,
                        spacingTop: 0,
                        spacingRight: 0,
                        spacingBottom: 0,
                        spacingLeft: 0,
                        events: {
                            click: clickChartHandler
                        }
                    },
                    tooltip: {
                        formatter: function() {
                            return false;
                        }
                    },
                    spacingTop: 0,
                    title: { text: null },
                    plotOptions: {
                        pie: {
                            shadow: false,
                            center: ['50%', '50%'],
                            point: {
                                events: {
                                    click: clickChartHandler
                                }
                            },
                            showInLegend: false
                        }
                    }
                }
            }, overrides || {});
        },

        _addPointForTopLevelItem: function(record, relatedCount) {
            var blocked = record.get('Blocked');
            var color = this._colorFromStatus(this._storyStates[record.get('ScheduleState')], blocked);
            var pointSize = record.get('PlanEstimate') || 1;

            this._chartData.push({
                name: record.get('FormattedID'),
                y: pointSize,
                color: color,
                rallyName: record.get('Name'),
                status: record.get('ScheduleState'),
                blocked: blocked,
                blockedReason: blocked ? record.get('BlockedReason') : null,
                hasChildren: relatedCount > 0,
                relatedCount: relatedCount,
                ref: record.get('_ref'),
                parentFormattedID: null
            });
        },

        _addPointForChildItem: function(parentFormattedID, pointSize, state, blocked) {
            var color = this._colorFromStatus(this._storyStates[state], blocked);

            this._childChartData.push({
                y: pointSize,
                color: color,
                status: state,
                blocked: blocked,
                hasChildren: false,
                relatedCount: 0,
                parentFormattedID: parentFormattedID
            });
        }
      
    });
})();

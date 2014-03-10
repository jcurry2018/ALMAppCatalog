(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.util.TimelineViewModel', {
        statics: {
            createFromStores: function (timeframePlanStoreWrapper, currentTimeframeRecord) {
                var _this = this;
                var timeframes = _.map(timeframePlanStoreWrapper.getTimeframeAndPlanRecords(), function(record) {
                    return _this._createTimeframe(record.timeframe);
                });

                return Ext.create('Rally.apps.roadmapplanningboard.util.TimelineViewModel',{
                    timeframes: timeframes,
                    currentTimeframe: this._createTimeframe(currentTimeframeRecord)
                });
            },

            _createTimeframe: function (timeframeRecord) {
                return {
                    startDate: timeframeRecord.get('startDate'),
                    endDate: timeframeRecord.get('endDate')
                };
            }
        },
        constructor: function (config) {
            var _this = this;

            this.currentTimeframe = config.currentTimeframe;
            this.timeframes = _.sortBy(_.reject(config.timeframes, function (tf) {
                return _.isEqual(tf, _this.currentTimeframe);
            }), 'startDate');
        },

        getPreviousTimeframe: function (currentTimeframe) {
            currentTimeframe = currentTimeframe || this.currentTimeframe;

            var startDate = currentTimeframe.startDate || currentTimeframe.endDate;
            var prevTimeframe = _.findLast(this.timeframes, function (tf) {
                return !startDate || tf.endDate < startDate;
            });

            return prevTimeframe || null;
        },

        getNextTimeframe: function (currentTimeframe) {
            currentTimeframe = currentTimeframe || this.currentTimeframe;

            var endDate = currentTimeframe.endDate || currentTimeframe.startDate;
            var nextTimeframe = endDate && _.find(this.timeframes, function (tf) {
                return tf.startDate > endDate;
            });

            return nextTimeframe || null;
        },

        isTimeframeOverlapping: function (newTimeframe) {
            return _.some(this.timeframes, function (timeframe) {
                var overlappingInside = this._isDateInRange(newTimeframe.startDate, timeframe) || this._isDateInRange(newTimeframe.endDate, timeframe);
                var overlappingOutside = newTimeframe.startDate <= timeframe.startDate && newTimeframe.endDate >= timeframe.endDate;
                return overlappingInside || overlappingOutside;
            }, this);
        },

        _isDateInRange: function (date, dateRange) {
            return date >= dateRange.startDate && date <= dateRange.endDate;
        }
    });
}).call(this);
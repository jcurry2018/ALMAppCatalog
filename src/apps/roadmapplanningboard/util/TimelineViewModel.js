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
                    start: timeframeRecord.get('startDate'),
                    end: timeframeRecord.get('endDate')
                };
            }
        },
        constructor: function (config) {
            var _this = this;

            this.currentTimeframe = config.currentTimeframe;
            this.timeframes = _.sortBy(_.reject(config.timeframes, function (tf) {
                return _.isEqual(tf, _this.currentTimeframe);
            }), 'start');
        },

        getPreviousTimeframe: function () {
            var start = this.currentTimeframe.start || this.currentTimeframe.end;
            var prevTimeframe = _.findLast(this.timeframes, function (tf) {
                return !start || tf.end < start;
            });

            return prevTimeframe || null;
        },

        getNextTimeframe: function () {
            var end = this.currentTimeframe.end || this.currentTimeframe.start;
            var nextTimeframe = end && _.find(this.timeframes, function (tf) {
                return tf.start > end;
            });

            return nextTimeframe || null;
        },

        setCurrentTimeframe: function (newTimeframe) {
            var prevTimeframe = this.getPreviousTimeframe();
            var nextTimeframe = this.getNextTimeframe();

            if ((newTimeframe.start && !Ext.isDate(newTimeframe.start)) ||
                (newTimeframe.end && !Ext.isDate(newTimeframe.end))) {
                throw 'Start and end date must be valid dates';
            }

            if (newTimeframe.start > newTimeframe.end) {
                throw 'Start date is after end date';
            }

            if(prevTimeframe && newTimeframe.start <= prevTimeframe.end) {
                throw 'Start date overlaps an earlier timeframe';
            }

            if(nextTimeframe && newTimeframe.end >= nextTimeframe.start) {
                throw 'End date overlaps a later timeframe';
            }

            this.currentTimeframe = newTimeframe;
        }
    });
}).call(this);
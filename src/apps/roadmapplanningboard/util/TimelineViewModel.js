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

        getPreviousTimeframe: function () {
            var startDate = this.currentTimeframe.startDate || this.currentTimeframe.endDate;
            var prevTimeframe = _.findLast(this.timeframes, function (tf) {
                return !startDate || tf.endDate < startDate;
            });

            return prevTimeframe || null;
        },

        getNextTimeframe: function () {
            var endDate = this.currentTimeframe.endDate || this.currentTimeframe.startDate;
            var nextTimeframe = endDate && _.find(this.timeframes, function (tf) {
                return tf.startDate > endDate;
            });

            return nextTimeframe || null;
        },

        setCurrentTimeframe: function (newTimeframe) {
            var prevTimeframe = this.getPreviousTimeframe();
            var nextTimeframe = this.getNextTimeframe();

            if ((newTimeframe.startDate && !Ext.isDate(newTimeframe.startDate)) ||
                (newTimeframe.endDate && !Ext.isDate(newTimeframe.endDate))) {
                throw 'Start and end date must be valid dates';
            }

            if (newTimeframe.startDate > newTimeframe.endDate) {
                throw 'Start date is after end date';
            }

            if(prevTimeframe && newTimeframe.startDate <= prevTimeframe.endDate) {
                throw 'Start date overlaps an earlier timeframe';
            }

            if(nextTimeframe && newTimeframe.endDate >= nextTimeframe.startDate) {
                throw 'End date overlaps a later timeframe';
            }

            this.currentTimeframe = newTimeframe;
        }
    });
}).call(this);
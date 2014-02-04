(function () {
    var Ext = window.Ext4 || window.Ext;

    /**
     * @private
     * This should never be called directly, but only through the {@link Rally.data.ModelFactory}
     */
    Ext.define('Rally.apps.roadmapplanningboard.AppModelFactory', {
        
        singleton: true,
        
        requires: [
            'Rally.apps.roadmapplanningboard.Model',
            'Rally.apps.roadmapplanningboard.Proxy'
        ],

        /**
         * @property
         * {String[]} modelTypes An array of types this factory knows how to handle. These
         */
        modelTypes: [
            'plan',
            'roadmap',
            'timeframe',
            'timeline'
        ],

        getPlanModel: function () {
            if (this.planModel) {
                return this.planModel;
            }
            this.planModel = Ext.define('Rally.apps.roadmapplanningboard.PlanModel', {
                extend: 'Rally.apps.roadmapplanningboard.Model',
                fields: [
                    {
                        name: 'id',
                        type: 'string',
                        persist: false
                    },
                    {
                        name: 'ref',
                        type: 'string',
                        persist: false
                    },
                    {
                        name: 'name',
                        type: 'string'
                    },
                    {
                        name: 'theme',
                        type: 'string'
                    },
                    {
                        name: 'lowCapacity',
                        type: 'int'
                    },
                    {
                        name: 'highCapacity',
                        type: 'int'
                    },
                    {
                        name: 'timeframe',
                        serialize: this._serializeModel
                    },
                    {
                        name: 'roadmap'
                    },
                    {
                        name: 'features',
                        type: 'collection'
                    },
                    {
                        name: 'updatable',
                        defaultValue: true
                    }
                ],
                proxy: {
                    type: 'roadmap',
                    url: Rally.environment.getContext().context.services.planning_service_url + '/roadmap/{roadmap.id}/plan/{id}'
                }
            });
            return this.planModel;
        },

        getRoadmapModel: function () {
            if (this.roadmapModel) {
                return this.roadmapModel;
            }
            this.roadmapModel = Ext.define('Rally.apps.roadmapplanningboard.RoadmapModel', {
                extend: 'Rally.apps.roadmapplanningboard.Model',
                fields: [
                    {
                        name: 'id',
                        type: 'string',
                        persist: false
                    },
                    {
                        name: 'ref',
                        type: 'string',
                        persist: false
                    },
                    {
                        name: 'name',
                        type: 'string'
                    },
                    {
                        name: 'plans',
                        serialize: this._getModelCollectionSerializer()
                    }
                ],
                proxy: {
                    type: 'roadmap',
                    url: Rally.environment.getContext().context.services.planning_service_url + '/roadmap'
                }
            });
            return this.roadmapModel;
        },
        /**
         * The server will give us Zulu time. We need to make sure we're normalizing for our timezone
         * and stripping the time since we only care about the date
         * @param value The value from the server
         * @returns {Ext.Date}
         * @private
         */
        _normalizeDate: function (value) {
            var date = Ext.Date.parse(value, 'c');
            if (date.getTime()) {
                return Ext.Date.clearTime(Ext.Date.add(date, Ext.Date.MINUTE, date.getTimezoneOffset()));
            }
        },

        getTimeframeModel: function () {
            if (this.timeframeModel) {
                return this.timeframeModel;
            }
            this.timeframeModel = Ext.define('Rally.apps.roadmapplanningboard.TimeframeModel', {
                extend: 'Rally.apps.roadmapplanningboard.Model',
                fields: [
                    {
                        name: 'id',
                        type: 'string',
                        persist: false
                    },
                    {
                        name: 'ref',
                        type: 'string',
                        persist: false
                    },
                    {
                        name: 'name',
                        type: 'string'
                    },
                    {
                        name: 'startDate',
                        type: 'date',
                        dateFormat: 'Y-m-d\\TH:i:s\\Z',
                        convert: this._normalizeDate
                    },
                    {
                        name: 'endDate',
                        type: 'date',
                        dateFormat: 'Y-m-d\\TH:i:s\\Z',
                        convert: this._normalizeDate
                    },
                    {
                        name: 'updatable',
                        type: 'boolean',
                        defaultValue: true
                    },
                    {
                        name: 'timeline'
                    }
                ],
                proxy: {
                    type: 'roadmap',
                    url: Rally.environment.getContext().context.services.timeline_service_url + '/timeline/{timeline.id}/timeframe/{id}'
                }
            });
            return this.timeframeModel;
        },

        getTimelineModel: function () {
            if (this.timelineModel) {
                return this.timelineModel;
            }
            this.timelineModel = Ext.define('Rally.apps.roadmapplanningboard.TimelineModel', {
                extend: 'Rally.apps.roadmapplanningboard.Model',
                fields: [
                    {
                        name: 'id',
                        type: 'string',
                        persist: false
                    },
                    {
                        name: 'ref',
                        type: 'string',
                        persist: false
                    },
                    {
                        name: 'name',
                        type: 'string'
                    },
                    {
                        name: 'timeframes',
                        type: 'collection',
                        serialize: this._getModelCollectionSerializer()
                    }
                ],
                proxy: {
                    type: 'roadmap',
                    url: Rally.environment.getContext().context.services.timeline_service_url + '/timeline'
                }
            });
            return this.timelineModel;
        },

        _serializeModelCollection: function (values, record) {
            var _this = this;

            return _.map(values, function(model) {
                return _this._serializeModel(model);
            });
        },

        _serializeModel: function (model) {
            return model.data || model;
        },

        _getModelCollectionSerializer: function () {
            var _this = this;

            return function() {
                return _this._serializeModelCollection.apply(_this, arguments);
            };
        }
    }, function () {
        Rally.data.ModelFactory.registerTypes(this.modelTypes, this);
    });

})();

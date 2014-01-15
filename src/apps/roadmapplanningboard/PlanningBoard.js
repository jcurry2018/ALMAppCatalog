(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.PlanningBoard', {
        extend: 'Rally.ui.cardboard.CardBoard',
        alias: 'widget.roadmapplanningboard',

        inject: ['timeframeStore', 'planStore', 'preliminaryEstimateStore'],

        requires: [
            'Rally.data.util.PortfolioItemHelper',
            'Rally.ui.cardboard.plugin.FixedHeader',
            'Rally.apps.roadmapplanningboard.PlanningBoardColumn',
            'Rally.apps.roadmapplanningboard.TimeframePlanningColumn',
            'Rally.apps.roadmapplanningboard.BacklogBoardColumn',
            'Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper'
        ],

        config: {
            roadmap: null,
            timeline: null,
            isAdmin: false,
            cardConfig: {
                fields: ['FormattedID', 'Owner', 'Name', 'Project', 'PreliminaryEstimate', 'Parent', 'LeafStoryCount', 'PercentDoneByStoryCount'],
                editable: true,
                skipDefaultFields: true
            },
            ddGroup: 'planningBoard',
            dropAllowed: "planningBoard",
            dropNotAllowed: "planningBoard",

            /**
             * @cfg {Object} Object containing Names and TypePaths of the lowest level portfolio item (eg: 'Feature') and optionally its parent (eg: 'Initiative')
             */
            typeNames: {},

            /**
             * @cfg {Number} The duration of the theme slide animation in milliseconds
             */
            slideDuration: 500
        },

        clientMetrics: [
            {
                method: '_clickCollapseButton',
                descriptionProperty: '_getClickAction'
            },
            {
                method: '_clickExpandButton',
                descriptionProperty: '_getClickAction'
            }
        ],

        initComponent: function () {
            if(!this.typeNames.child || !this.typeNames.child.name) {
                throw 'typeNames must have a child property with a name';
            }

            this.callParent(arguments);
        },

        /**
         * @cfg {Boolean}
         * Toggle whether the theme is expanded or collapsed
         */
        showTheme: true,

        cls: 'roadmap-board cardboard',

        shouldRetrieveModels: function () {
            return !this.columns || this.columns.length === 0;
        },

        onModelsRetrieved: function (callback) {
            Deft.Promise.all([this._loadTimeframeStore(), this._loadPlanStore(), this._loadPreliminaryStore()]).then({
                success: function (results) {
                    this.buildColumns();
                    callback.call(this);
                },
                failure: function (operation) {
                    var service = operation.storeServiceName || 'External';
                    Rally.ui.notify.Notifier.showError({message: 'Failed to load: ' + service + ' service data load issue'});
                },
                scope: this
            });
        },

        _loadPlanStore: function () {
            return this.planStore.load({
                params: {
                    roadmap: {
                        id: this.roadmap.getId()
                    }
                },
                reqester: this,
                storeServiceName: 'Planning'
            });
        },

        _loadTimeframeStore: function () {
            return this.timeframeStore.load({
                params: {
                    timeline: {
                        id: this.timeline.getId()
                    }
                },
                requester: this,
                storeServiceName: 'Timeline'
            });
        },

        _loadPreliminaryStore: function() {
            return this.preliminaryEstimateStore.load();
        },

        /**
         * @inheritDoc
         */
        renderColumns: function () {
            this.callParent(arguments);
            this.drawThemeToggle();
        },

        /**
         * This method will build an array of columns from timeframe and plan stores
         * @returns {Array} columns
         */
        buildColumns: function () {
            this.timeframePlanStoreWrapper = Ext.create('Rally.apps.roadmapplanningboard.util.TimeframePlanStoreWrapper', {
                timeframeStore: this.timeframeStore,
                planStore: this.planStore
            });

            var planColumns = _.map(this.timeframePlanStoreWrapper.getTimeframeAndPlanRecords(), function (record) {
                return this._addColumnFromTimeframeAndPlan(record.timeframe, record.plan);
            }, this);

            this.columns = [this._getBacklogColumnConfig()].concat(planColumns);

            return this.columns;
        },

        _getBacklogColumnConfig: function () {
            return {
                xtype: 'backlogplanningcolumn',
                types: this.types,
                typeNames: this.typeNames,
                planStore: this.planStore,
                cls: 'column backlog',
                cardConfig: {
                    preliminaryEstimateStore: this.preliminaryEstimateStore
                }
            };
        },

        /**
         * Return the backlog column if it exists
         * @returns {Rally.apps.roadmapplanningboard.BacklogBoardColumn} column The backlog column of the cardboard
         */
        getBacklogColumn: function () {
            var columns = this.getColumns();

            if (!Ext.isEmpty(columns)) {
                return columns[0];
            } else {
                return null;
            }
        },

        /**
         * Get the first record of the cardboard
         * @returns {Rally.data.Record}
         */
        getFirstRecord: function () {
            var cards;
            var record = null;
            var column = this.getBacklogColumn();

            if (column) {
                cards = column.getCards();
                if (!Ext.isEmpty(cards)) {
                    record = cards[0].getRecord();
                }
            }
            return record;
        },

        /**
         * Draws the theme toggle buttons to show/hide the themes
         */
        drawThemeToggle: function () {
            this._destroyThemeButtons();

            this.themeCollapseButton = Ext.create('Ext.Component', {
                cls: ['themeButton', 'themeButtonCollapse'],
                autoEl: {
                    tag: 'a',
                    href: '#',
                    title: 'Hide themes'
                },
                listeners: {
                    click: {
                        element: 'el',
                        fn: this._clickCollapseButton,
                        scope: this
                    }
                }
            });
            var themeContainer = _.last(this.getEl().query('.theme_container'));
            if (themeContainer) {
                this.themeCollapseButton.render(themeContainer, 0);
            }

            this.themeExpandButton = Ext.create('Ext.Component', {
                cls: ['themeButton', 'themeButtonExpand'],
                hidden: this.showTheme,
                autoEl: {
                    tag: 'a',
                    href: '#',
                    title: 'Show themes'
                },
                listeners: {
                    click: {
                        element: 'el',
                        fn: this._clickExpandButton,
                        scope: this
                    }
                },
                renderTo: _.last(this.getEl().query('.column-header'))
            });
        },

        _clickCollapseButton: function () {
            this.showTheme = false;
            _.map(this._getThemeContainerElements(), this._collapseThemeContainers, this);
        },

        _clickExpandButton: function () {
            this.showTheme = true;
            this.themeExpandButton.hide();
            _.map(this._getThemeContainerElements(), this._expandThemeContainers, this);
        },

        _getThemeContainerElements: function () {
            return _.map(this.getEl().query('.theme_container'), Ext.get);
        },

        _collapseThemeContainers: function (el) {
            el.slideOut('t', {
                duration: this.getSlideDuration(),
                listeners: {
                    afteranimate: function () {
                        el.setStyle('display', 'none'); // OMG Ext. Y U SUCK?
                        this.themeExpandButton.show(true);
                        this.fireEvent('headersizechanged');
                    },
                    scope: this
                }
            });
        },

        _expandThemeContainers: function (el) {
            el.slideIn('t', {
                duration: this.getSlideDuration(),
                listeners: {
                    afteranimate: function () {
                        this.fireEvent('headersizechanged');
                    },
                    scope: this
                }
            });
        },

        destroy: function () {
            this._destroyThemeButtons();
            this.callParent(arguments);
        },

        _destroyThemeButtons: function () {
            if (this.themeCollapseButton && this.themeExpandButton) {
                this.themeCollapseButton.destroy();
                this.themeExpandButton.destroy();
            }
        },

        _addColumnFromTimeframeAndPlan: function (timeframe, plan) {
            return {
                xtype: 'timeframeplanningcolumn',
                timeframeRecord: timeframe,
                planRecord: plan,
                timeframePlanStoreWrapper: this.timeframePlanStoreWrapper,
                types: this.types,
                typeNames: this.typeNames,
                columnHeaderConfig: {
                    record: timeframe,
                    fieldToDisplay: 'name',
                    editable: this.isAdmin
                },
                cardConfig: {
                    preliminaryEstimateStore: this.preliminaryEstimateStore
                },
                editPermissions: {
                    capacityRanges: this.isAdmin,
                    theme: this.isAdmin,
                    timeframeDates: this.isAdmin
                },
                dropControllerConfig: {
                    dragDropEnabled: this.isAdmin
                },
                isMatchingRecord: function (featureRecord) {
                    return plan && _.find(plan.get('features'), function (feature) {
                        return feature.id === featureRecord.getId().toString();
                    });
                }
            };
        },

        _getClickAction: function () {
            var themesVisible = this.showTheme;
            var message = "Themes toggled from [" + !themesVisible + "] to [" + themesVisible + "]";
            return message;
        }
    });

})();

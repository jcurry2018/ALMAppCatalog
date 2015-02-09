(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.PlanningGridBoard', {
        extend: 'Rally.ui.gridboard.GridBoard',
        alias: 'widget.roadmapplanninggridboard',
        requires: [
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.gridboard.plugin.GridBoardFilterControl',
            'Rally.ui.filter.view.CustomQueryFilter',
            'Rally.ui.filter.view.ParentFilter',
            'Rally.ui.filter.view.OwnerPillFilter',
            'Rally.ui.filter.view.TagPillFilter',
            'Rally.ui.gridboard.plugin.GridBoardFeedback',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.apps.roadmapplanningboard.PlanningBoard',
            'Rally.apps.roadmapplanningboard.plugin.RoadmapScrollable',
            'Rally.apps.roadmapplanningboard.plugin.RoadmapCollapsableFixedHeader'
        ],

        cls: 'rui-gridboard roadmap-board',

        toggleState: 'board',
        stateId: 'roadmapgridboard',

        config: {
            /**
             * @cfg {Rally.data.Model} The roadmap to use
             */
            roadmap: null,

            /**
             * @cfg {Rally.data.Model} The timeline to use
             */
            timeline: null,

            /**
             * @cfg {Object} A Rally context
             */
            context: null,

            /**
             * @cfg {Object} Object containing Names and TypePaths of the lowest level portfolio item (eg: 'Feature') and optionally its parent (eg: 'Initiative')
             */
            typeNames: {},

            /**
             * @cfg {Boolean} If the user is an admin
             */
            isAdmin: false
        },

        initComponent: function () {
            if(!this.typeNames.child || !this.typeNames.child.name) {
                throw 'typeNames must have a child property with a name';
            }

            this.plugins = [
                {
                    ptype: 'rallygridboardaddnew',
                    addNewControlConfig: {
                        listeners: {
                            beforecreate: this._onBeforeCreate,
                            beforeeditorshow: this._onBeforeCreate,
                            scope: this
                        },
                        fieldLabel: 'New ' + this.typeNames.child.name
                    }
                },
                {
                    ptype: 'rallygridboardfiltercontrol',
                    filterControlConfig: {
                        cls: 'small gridboard-filter-control',
                        margin: '3 10 3 7',
                        stateful: true,
                        stateId: this.context.getScopedStateId('roadmapplanningboard-filter-button'),
                        items: this._getFilterItems()
                    }
                },
                {
                    ptype: 'rallygridboardfieldpicker',
                    headerPosition: 'left',
                    boardFieldDefaults: ['PreliminaryEstimate', 'Discussions', 'UserStories', 'Name'],
                    gridFieldBlackList: ['DragAndDropRank', 'DisplayColor'],
                    boardFieldBlackList: ['State', 'CreationDate', 'Description', 'Notes'],
                    stateful: true,
                    stateId: this.getContext().getScopedStateId('fields')
                },
                {
                    ptype: 'rallygridboardfeedback',
                    feedbackDialogConfig: {
                        title: 'What do you think about the Roadmap Planning Board?',
                        subject: 'Roadmap Planning Board',
                        feedbackId: 'roadmapplanningboard',
                        helpInfo: {
                            id: 282,
                            text: "What's coming soon?"
                        }
                    }
                }
            ];

            this.cardBoardConfig = Ext.merge({
                xtype: 'roadmapplanningboard',
                context: this.context,
                roadmap: this.roadmap,
                timeline: this.timeline,
                isAdmin: this.isAdmin,
                types: this.modelNames,
                typeNames: this.typeNames,
                firstLoad: this.firstLoad,
                attribute: 'Name',
                plugins: [
                    { ptype: 'rallytimeframescrollablecardboard', timeframeColumnCount: 3 },
                    { ptype: 'rallyroadmapcollapsableheader' }
                ]
            }, this.cardBoardConfig);

            this.callParent(arguments);
        },

        _createPillFilterItem: function(typeName, config) {
            return Ext.apply({
                xtype: typeName,
                margin: '-15 0 5 0',
                showPills: true,
                showClear: true
            }, config);
        },

        _getFilterItems: function () {
            var filterItems = [];

            if (this.typeNames.parent) {
                filterItems.push({
                    xtype: 'rallyparentfilter',
                    modelType: this.typeNames.parent.typePath,
                    modelName: this.typeNames.parent.name,
                    prependFilterFieldWithFormattedId: true,
                    storeConfig: {
                        context: {
                            project: null
                        }
                    }
                });
            }

            filterItems.push(
                this._createPillFilterItem('rallyownerpillfilter', {
                    filterChildren: false,
                    project: this.context.getProject(),
                    showPills: false
                }),
                this._createPillFilterItem('rallytagpillfilter', {remoteFilter: true}),
                { xtype: 'rallycustomqueryfilter', filterHelpId: 194 }
            );

            return filterItems;
        },

        /**
         * This method is fired by AddNew and will run before the artifact is created.
         * @private
         */
        _onBeforeCreate: function (addNew, record, params) {
            // the order of arguments is different between beforecreate and beforeeditorshow
            if (!record.isModel) {
                params = record;
            }
            var rankRecord = this.getGridOrBoard().getFirstRecord();
            if (rankRecord) {
                params.rankAbove = rankRecord.getUri();
            }
        }
    });

})();

(function () {
    var Ext = window.Ext4 || window.Ext;

    /**
     * PI Kanban Board App
     * Displays a cardboard and a type selector. Board shows States for the selected Type.
     */
    Ext.define('Rally.apps.portfoliokanban.PortfolioKanbanApp', {
        extend: 'Rally.apps.common.PortfolioItemsGridBoardApp',
        requires: [
            'Rally.apps.portfoliokanban.PortfolioKanbanCard',
            'Rally.apps.portfoliokanban.PortfolioKanbanPolicy',
            'Rally.ui.gridboard.plugin.BoardPolicyDisplayable',
            'Rally.ui.cardboard.plugin.ColumnPolicy',
            'Rally.ui.cardboard.Column',
            'Rally.ui.cardboard.Card',
            'Rally.util.Help',
            'Rally.util.Test',
            'Deft.Deferred'
        ],

        autoScroll: false,
        appName: 'Portfolio Kanban',
        cls: 'portfolio-kanban',

        config: {
            toggleState: 'board',
            statePrefix: 'portfolio-kanban',
            defaultSettings: {
                fields: 'Discussion,PercentDoneByStoryCount,UserStories,Milestones'
            }
        },

        mixins: [
          "Rally.clientmetrics.ClientMetricsRecordable"
        ],

        clientMetrics: [
            {
                method: '_showHelp',
                description: 'portfolio-kanban-show-help'
            }
        ],

        getSettingsFields: function () {
            return [
                {
                    type: 'project'
                },
                {
                    type: 'query',
                    config: {
                        plugins: [
                            {
                                ptype: 'rallyhelpfield',
                                helpId: 271
                            },
                            'rallyfieldvalidationui'
                        ]
                    }
                }
            ];
        },

        _createFilterItem: function(typeName, config) {
            return Ext.apply({
                xtype: typeName,
                margin: '-15 0 5 0',
                showPills: true,
                showClear: true
            }, config);
        },

        getHeaderControls: function () {
            var ctls = this.callParent(arguments);
            ctls.unshift(this._buildHelpComponent());
            ctls.push(this._buildFilterInfo());
            return ctls;
        },

        getGridBoardPlugins: function () {
            return this.callParent(arguments).concat([{
                ptype: 'rallyboardpolicydisplayable',
                pluginId: 'boardPolicyDisplayable',
                prefKey: 'piKanbanPolicyChecked',
                checkboxConfig: {
                    boxLabel: 'Show Policies',
                    margin: '2 5 5 5'
                }
            }]);
        },

        getFilterControlConfig: function () {
            var config = this.callParent(arguments);
            return _.merge(config, {
                blackListFields: _.union(config.blackListFields, ['State'])
            });
        },

        getCardConfig: function () {
            return {
                xtype: 'rallyportfoliokanbancard'
            };
        },

        getCardBoardConfig: function () {
            var config = _.merge(this.callParent(arguments), {
                loadDescription: 'Portfolio Kanban'
            });
            if(this.getContext().isFeatureEnabled('S79575_ADD_SWIMLANES_TO_PI_KANBAN')) {
                Ext.apply(config, {
                    rowConfig: {
                        field: 'Owner'
                    }
                });
            }
            return config;
        },

        getCardBoardColumnPlugins: function (state) {
            var policyPlugin = this.gridboard && this.gridboard.getPlugin('boardPolicyDisplayable');
            return {
                ptype: 'rallycolumnpolicy',
                policyCmpConfig: {
                    xtype: 'rallyportfoliokanbanpolicy',
                    hidden: !policyPlugin || !policyPlugin.isChecked(),
                    title: 'Exit Policy',
                    stateRecord: state
                }
            };
        },

        publishComponentReady: function () {
            this.fireEvent('contentupdated');
            this.callParent(arguments);
            Rally.environment.getMessageBus().publish(Rally.Message.piKanbanBoardReady);
        },

        _buildHelpComponent: function (config) {
            return this.isFullPageApp ? null : Ext.create('Ext.Component', Ext.apply({
                cls: 'help-field ' + Rally.util.Test.toBrowserTestCssClass('portfolio-kanban-help-container'),
                renderTpl: Rally.util.Help.getIcon({
                    id: 265
                })
            }, config));
        },

        _buildFilterInfo: function () {
            this.filterInfo = this.isFullPageApp ? null : Ext.create('Rally.ui.tooltip.FilterInfo', {
                projectName: this.getSetting('project') && this.getContext().get('project').Name || 'Following Global Project Setting',
                scopeUp: this.getSetting('projectScopeUp'),
                scopeDown: this.getSetting('projectScopeDown'),
                query: this.getSetting('query')
            });

            return this.filterInfo;
        }
    });
})();

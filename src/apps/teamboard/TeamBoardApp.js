(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.TeamBoardApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.apps.teamboard.TeamBoardCard',
            'Rally.apps.teamboard.TeamBoardColumn',
            'Rally.apps.teamboard.TeamBoardProjectRecordsLoader',
            'Rally.apps.teamboard.TeamBoardSettings',
            'Rally.apps.teamboard.TeamBoardUtil',
            'Rally.data.ModelFactory',
            'Rally.ui.cardboard.CardBoard',
            'Rally.ui.cardboard.plugin.Scrollable'
        ],

        config: {
            defaultSettings: {
                cardFields: 'OfficeLocation,Phone',
                groupBy: 'Role'
            }
        },

        cls: 'team-board-app',
        settingsScope: 'workspace',

        launch: function() {
            Rally.data.ModelFactory.getModel({
                type: 'User',
                scope: this,
                success: this._onUserModelLoaded
            });
        },

        getSettingsFields: function() {
            return Rally.apps.teamboard.TeamBoardSettings.getFields(this.userModel);
        },

        _onUserModelLoaded: function(userModel) {
            this.userModel = userModel;

            Rally.apps.teamboard.TeamBoardProjectRecordsLoader.load(this.getSetting('teamOids'), this._onTeamsLoaded, this);
        },

        _showNoDataMessage: function(msg){
            this.add({
                xtype: 'component',
                cls: 'no-data',
                html: '<p>' + msg + '</p>'
            });
        },

        _onTeamsLoaded: function(teams) {
            if (teams.length === 0) {
                this._showNoDataMessage('You do not have access to any of the teams chosen to be shown in this app');
                this._publishComponentReady();
                return;
            }

            this.add(this._getCardboardConfig(teams));
        },

        _getCardboardConfig: function(teams) {
            var groupBy = this.getSetting('groupBy');
            groupBy = groupBy && this.userModel.hasField(groupBy) ? groupBy : undefined;

            return {
                xtype: 'rallycardboard',
                attribute: 'TeamMemberships',
                cardConfig: {
                    xtype: 'rallyteamboardcard',
                    fields: this.getSetting('cardFields') ? this.getSetting('cardFields').split(',') : [],
                    groupBy: groupBy
                },
                context: this.getContext(),
                columns: Ext.Array.map(teams, function(team) {
                    return {
                        xtype: 'rallyteamcolumn',
                        columnHeaderConfig: {
                            xtype: 'rallycardboardcolumnheader',
                            headerTpl: Rally.apps.teamboard.TeamBoardUtil.linkToAdminPage(team, team.get('_refObjectName'), 'users')
                        },
                        groupBy: groupBy,
                        value: team.get('_ref')
                    };
                }, this),
                listeners: {
                    load: this._onBoardLoad,
                    toggle: this._publishContentUpdated,
                    recordupdate: this._publishContentUpdatedNoDashboardLayout,
                    recordcreate: this._publishContentUpdatedNoDashboardLayout,
                    scope: this
                },
                plugins: [
                    {
                        ptype: 'rallyscrollablecardboard',
                        containerEl: this.getEl()
                    }
                ],
                readOnly: !Rally.environment.getContext().getPermissions().isWorkspaceOrSubscriptionAdmin(),
                storeConfig: {
                    filters: [ {property: 'Disabled', value: 'false'} ],
                    sorters: [ {direction: 'ASC', property: 'FirstName'} ]
                },
                types: ['User']
            };
        },

        _onBoardLoad: function(){
            this._publishContentUpdated();
            this._publishComponentReady();
        },

        _publishComponentReady: function() {
            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this);
            }
        },

        _publishContentUpdated: function() {
            this.fireEvent('contentupdated');
        },

        _publishContentUpdatedNoDashboardLayout: function() {
            this.fireEvent('contentupdated', {dashboardLayout: false});
        }
    });

})();
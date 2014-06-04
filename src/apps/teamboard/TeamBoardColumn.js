(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.TeamBoardColumn', {
        extend: 'Rally.ui.cardboard.Column',
        alias: 'widget.rallyteamcolumn',
        requires: [
            'Rally.apps.teamboard.TeamBoardDropController',
            'Rally.apps.teamboard.plugin.TeamBoardUserIterationCapacity',
            'Rally.apps.teamboard.plugin.TeamBoardWip',
            'Rally.ui.cardboard.plugin.ColumnCardCounter',
            'Rally.ui.combobox.IterationComboBox'
        ],

        plugins: [
            {ptype: 'rallycolumncardcounter'},
            {ptype: 'rallyteamboardwip'},
            {ptype: 'rallyteamboarduseriterationcapacity'}
        ],

        config: {
            dropControllerConfig: {
                ptype: 'rallyteamboarddropcontroller'
            }
        },

        initComponent: function() {
            this.callParent(arguments);

            this.addEvents('iterationcomboready');
            this.on('storeload', this._addIterationCombo, this);
        },

        assign: function(record){
            // Don't need to do anything to the User record
        },

        getStoreFilter: function(model) {
            return {
                property: this.attribute,
                operator: 'contains',
                value: this.getValue()
            };
        },

        isMatchingRecord: function(record){
            return true;
        },

        _addIterationCombo: function() {
            this.getColumnHeader().add({
                xtype: 'container',
                cls: 'team-board-iteration-section',
                items: [{
                    xtype: 'rallyiterationcombobox',
                    allowNoEntry: true,
                    listeners: {
                        ready: this._onIterationComboReady,
                        scope: this
                    },
                    storeConfig: {
                        context: {
                            project: this.getValue(),
                            projectScopeDown: false,
                            projectScopeUp: false
                        }
                    }
                }]
            });
        },

        _onIterationComboReady: function(combo) {
            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this);
            }

            this.fireEvent('iterationcomboready', this, combo);
        }
    });

})();
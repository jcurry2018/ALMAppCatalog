(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.TeamBoardColumn', {
        extend: 'Rally.ui.cardboard.Column',
        alias: 'widget.rallyteamcolumn',
        requires: [
            'Rally.apps.teamboard.plugin.TeamBoardDropController',
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
            this.on('ready', this._addIterationCombo, this, { single: true });
        },

        assign: function(record){
            // Don't need to do anything to the User record
        },

        getAllFetchFields: function() {
            return this.groupBy ? _.union(this.callParent(arguments), [this.groupBy]) : this.callParent(arguments);
        },

        getIterationRef: function() {
            return this.getColumnHeader().down('rallyiterationcombobox').getValue();
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

        _sortRecords: function(records) {
            var groupBy = this.groupBy;
            if(groupBy) {
                var groupedRecords = _.groupBy(this.getStore().getRange(), function(record){
                    return record.get(groupBy);
                });

                records.sort(function(record1, record2){
                    var value1 = record1.get(groupBy);
                    var value2 = record2.get(groupBy);
                    var frequency1 = value1 && value1 !== 'None' ? (groupedRecords[value1] ? groupedRecords[value1].length : 1) : Infinity;
                    var frequency2 = value2 && value2 !== 'None' ? (groupedRecords[value2] ? groupedRecords[value2].length : 1) : Infinity;
                    return (frequency1 - frequency2) || value1.localeCompare(value2) || record1.get('FirstName').localeCompare(record2.get('FirstName'));
                }, this);
            } else {
                this.callParent(arguments);
            }
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
                    maxWidth: this.getMinWidth() - 10,
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
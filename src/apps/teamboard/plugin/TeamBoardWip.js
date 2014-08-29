(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.plugin.TeamBoardWip', {
        alias: 'plugin.rallyteamboardwip',
        extend: 'Rally.apps.teamboard.plugin.TeamBoardIterationAwarePlugin',
        requires: ['Rally.data.wsapi.Filter', 'Rally.util.DateTime'],

        inheritableStatics: {
            _inProgressDuring: function(iterationRecord) {
                return Rally.data.wsapi.Filter.and([
                    {property: 'ActualStartDate', operator: '<=', value: Rally.util.DateTime.toIsoString(iterationRecord.get('EndDate'))},
                    Rally.data.wsapi.Filter.or([
                        {property: 'ActualEndDate', operator: '>=', value: Rally.util.DateTime.toIsoString(iterationRecord.get('StartDate'))},
                        {property: 'ActualEndDate', value: 'null'}
                    ])
                ]);
            },

            _inProgressNow: function() {
                return Rally.data.wsapi.Filter.and([
                    {property: 'ActualStartDate', operator: '!=', value: 'null'},
                    {property: 'ActualEndDate', value: 'null'}
                ]);
            }
        },

        onIterationComboReady: function(cmp, combo){
            this.wipContainer = combo.up().add({
                xtype: 'container',
                cls: 'wip-container'
            });

            this.callParent(arguments);
        },

        showData: function(iterationRecord){
            if(!Rally.environment.getContext().getSubscription().isModuleEnabled('Rally Portfolio Manager')) {
                return;
            }

            this.wipContainer.removeAll();

            Ext.create('Rally.data.wsapi.Store', {
                autoLoad: {
                    callback: this._onWipLoaded,
                    scope: this
                },
                context: {
                    project: this.cmp.getValue(),
                    projectScopeDown: false,
                    projectScopeUp: false
                },
                fetch: 'FormattedID,Name',
                filters: Rally.data.wsapi.Filter.and([
                    {property: 'Ordinal', value: 0},
                    iterationRecord ? this.self._inProgressDuring(iterationRecord) : this.self._inProgressNow()
                ]),
                model: Ext.identityFn('PortfolioItem')
            });
        },

        _onWipLoaded: function(wipRecords) {
            _.each(wipRecords, function(record){
                this.wipContainer.add({
                    xtype: 'component',
                    cls: 'ellipses wip-item',
                    html: Rally.util.DetailLink.getLink({
                        record: record,
                        text: record.get('FormattedID')
                    }) + ': ' + record.get('Name')
                });
            }, this);
        }
    });
})();
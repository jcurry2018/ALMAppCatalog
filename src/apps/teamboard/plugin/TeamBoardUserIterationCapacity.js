(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.plugin.TeamBoardUserIterationCapacity', {
        alias: 'plugin.rallyteamboarduseriterationcapacity',
        extend: 'Rally.apps.teamboard.plugin.TeamBoardIterationAwarePlugin',
        requires: ['Rally.ui.cardboard.plugin.CardContentRight', 'Rally.ui.grid.Grid'],

        inheritableStatics: {
            _getProgressBarTpl: function() {
                this.progressBarTpl = this.progressBarTpl || Ext.create('Rally.ui.renderer.template.progressbar.ProgressBarTemplate', {
                    calculateColorFn: function(recordData) {
                        return recordData.Load > 1 ? '#ec0000' : '#76c10f';
                    },
                    isClickable: true,
                    height: '14px',
                    percentDoneName: 'Load',
                    width: '60px'
                });
                return this.progressBarTpl;
            }
        },

        onIterationComboReady: function(cmp, combo){
            this.callParent(arguments);

            this.cmp.on('cardupdated', function(){
                this.showData(this.findIterationRecord(combo.getValue(), combo));
            }, this);
        },

        showData: function(iterationRecord){
            if(iterationRecord) {
                iterationRecord.getCollection('UserIterationCapacities', {
                    autoLoad: true,
                    fetch: _.union(['Capacity', 'Iteration', 'Load', 'TaskEstimates', 'User'], this.cmp.getAllFetchFields()),
                    limit: Infinity,
                    listeners: {
                        load: function (store, records) {
                            this._updateCapacities(records, true);
                        },
                        scope: this
                    }
                });
            }else{
                this._updateCapacities([], false);
            }
        },

        _findUserIterationCapacityFor: function(userRecord, userIterationCapacityRecords) {
            return _.find(userIterationCapacityRecords, function(record){
                return record.get('User')._ref === userRecord.get('_ref');
            });
        },

        _getHasCapacityHtml: function(record) {
            return Ext.create('Rally.ui.renderer.template.CardPlanEstimateTemplate', record.get('Capacity'), 'Capacity').apply();
        },

        _getAddCapacityHtml: function() {
            return Ext.create('Rally.ui.renderer.template.CardPlanEstimateTemplate', '--', 'Capacity', 'no-estimate').apply();
        },

        _showCapacityOnCard: function(card, uicRecord, showSwipe) {
            var topEl = card.getEl().down('.' + Rally.ui.cardboard.plugin.CardContentRight.TOP_SIDE_CLS);
            var bottomEl = card.getEl().down('.' + Rally.ui.cardboard.plugin.CardContentRight.BOTTOM_SIDE_CLS);
            if(uicRecord){
                topEl.update(this.self._getProgressBarTpl().apply(uicRecord.data));
                topEl.on('click', function(e, targetEl){
                    this._showTasksGrid(Ext.get(targetEl), uicRecord);
                }, this, {delegate: '.progress-bar-container'});

                bottomEl.update(this._getHasCapacityHtml(uicRecord));
            }else{
                topEl.update('');
                bottomEl.update(showSwipe ? this._getAddCapacityHtml() : '');
            }

            if(showSwipe){
                card.getEl().addCls('rui-card-swipe');
            }else{
                card.getEl().removeCls('rui-card-swipe');
            }
        },

        _showTasksGrid: function(target, uicRecord) {
            Ext.create('Rally.ui.popover.Popover', {
                items: [{
                    xtype: 'rallygrid',
                    columnCfgs: ['FormattedID', 'Name', 'Owner', 'State', 'Estimate', 'ToDo', 'Actuals', 'Blocked'],
                    model: Ext.identityFn('Task'),
                    storeConfig: {
                        context: {
                            project: this.cmp.getValue(),
                            projectScopeDown: false,
                            projectScopeUp: false
                        },
                        filters: [
                            {property: 'Iteration', value: uicRecord.get('Iteration')._ref},
                            {property: 'Owner', value: uicRecord.get('User')._ref}
                        ]
                    }
                }],
                target: target,
                title: 'Tasks',
                width: 700
            });
        },

        _updateCapacities: function(userIterationCapacityRecords, showSwipe) {
            _.each(this.cmp.getCards(), function(card){
                var uicRecord = this._findUserIterationCapacityFor(card.getRecord(), userIterationCapacityRecords);
                Ext.Array.remove(userIterationCapacityRecords, uicRecord);
                if(card._isNonTeamMember && !uicRecord) {
                    this.cmp.removeCard(card, true);
                }else{
                    this._showCapacityOnCard(card, uicRecord, showSwipe);
                }
            }, this);

            _.each(userIterationCapacityRecords, function(uicRecord){
                var record = new this.cmp.model[0](uicRecord.get('User'));
                record.set('updatable', false);

                var card = this.cmp.createAndAddCard(record, null, false, {
                    cls: 'rui-card non-team-member-card',
                    _isNonTeamMember: true
                });

                this._showCapacityOnCard(card, uicRecord, showSwipe);
            }, this);
        }
    });
})();

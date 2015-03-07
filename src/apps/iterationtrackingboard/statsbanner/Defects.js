(function() {
    var Ext = window.Ext4 || window.Ext;

    /**
     * shows defects active for timebox
     */
    Ext.define('Rally.apps.iterationtrackingboard.statsbanner.Defects', {
        extend: 'Rally.apps.iterationtrackingboard.statsbanner.BannerWidget',
        alias:'widget.statsbannerdefects',
        requires: [],

        config: {
            context: null,
            store: null,
            data: {
                activeCount: 0
            }
        },

        tpl: [
            '<div class="expanded-widget">',
            '<div class="stat-title">Defects</div>',
            '<div class="stat-metric">',
            '<div class="metric-icon icon-defect"></div>{activeCount}',
            '<div class="stat-secondary">Active</div>',
            '</div>',
            '</div>',
            '<div class="collapsed-widget">',
            '<span class="metric-icon icon-defect"></span>',
            '<div class="stat-title">Defects</div>',
            '<div class="stat-metric">{activeCount}</div>',
            '</div>'
        ],

        initComponent: function() {
            this.mon(this.store, 'datachanged', this.onDataChanged, this);
            this.callParent(arguments);
        },

        onDataChanged: function() {
            this.update(this._getRenderData());
            this.fireEvent('ready', this);
        },

        _getActiveDefectCount: function() {
            var activeDefects = 0;
            _.each(this.store.getRange(), function(record){
                var defectSummary = record.get('Summary') && record.get('Summary').Defects;
                if (defectSummary) {
                    _.each(defectSummary.State, function(count, state) {
                        if (state !== 'Closed') {
                            activeDefects += count;
                        }
                    }, this);
                } else if(record.self.typePath === 'defect' && record.get('State') !== 'Closed') {
                    activeDefects++;
                }
            }, this);
            return activeDefects;
        },

        _getRenderData: function() {
            return {activeCount: this._getActiveDefectCount()};
        }
    });
})();
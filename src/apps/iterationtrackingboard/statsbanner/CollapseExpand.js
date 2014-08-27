(function() {
    var Ext = window.Ext4 || window.Ext;

    /**
     * shows collapse/expand toggle for stats banner
     */
    Ext.define('Rally.apps.iterationtrackingboard.statsbanner.CollapseExpand', {
        extend: 'Rally.apps.iterationtrackingboard.statsbanner.BannerWidget',
        alias:'widget.statsbannercollapseexpand',
        requires: [],
        mixins: [
            'Rally.clientmetrics.ClientMetricsRecordable'
        ],

        tpl: [
            '<div class="expanded-widget">',
            '<div class="toggle-icon icon-collapse-row"></div>',
            '</div>',
            '<div class="collapsed-widget">',
            '<div class="toggle-icon icon-expand-row"></div>',
            '</div>'
        ],

        componentCls: 'collapse-expand',

        bubbleEvents: ['collapse', 'expand'],

        afterRender: function() {
            this.callParent(arguments);
            this.parentComponent.getEl().on('click', this._onCollapseExpandClick, this);
            this.fireEvent('ready', this);
        },

        _onCollapseExpandClick: function (event, target) {
            if (this.expanded) {
                if (target.getAttribute('class').indexOf('toggle-icon') > -1 || Ext.get(target).down('div .toggle-icon')) {
                    this.fireEvent('collapse', this);
                }
            } else {
                this.fireEvent('expand', this);
            }
        },

        expand: function() {
            this.recordAction({
                description: 'Expand statsbanner'
            });
            this.callParent(arguments);
            this.doComponentLayout();
        },

        collapse: function() {
            this.recordAction({
                description: 'Collapse statsbanner'
            });
            this.callParent(arguments);
            this.doComponentLayout();
        }
    });
})();
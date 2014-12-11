(function() {
    var Ext = window.Ext4 || window.Ext;

    /**
     * Defines a task board row header on a board that hooks up work product popovers
     * to the work product formatted id links in each row header
     *
     */
    Ext.define('Rally.apps.taskboard.TaskBoardHeader', {
        extend: 'Rally.ui.cardboard.row.Header',
        alias: 'widget.rallytaskboardrowheader',

        requires: [
            'Rally.ui.popover.PopoverFactory'
        ],

        mixins: {
            clientMetrics: 'Rally.clientmetrics.ClientMetricsRecordable'
        },

        initComponent: function() {
            this.callParent(arguments);
            this._delayedTask = Ext.create('Ext.util.DelayedTask', this._showPopover, this);
            this.on('afterrender', function() {
                this.getEl().on('mouseover', this._onMouseOver, this, {delegate: '.formatted-id-link'});
                this.getEl().on('mouseout', this._onMouseOut, this, {delegate: '.formatted-id-link'});
            }, this, {single: true});
        },

        _onMouseOver: function() {
            this._delayedTask.delay(500, null, null);
        },

        _onMouseOut: function() {
            this._delayedTask.cancel();
        },

        _showPopover: function() {
            this.recordAction({description: 'showing work product popover on task board'});

            if (!Ext.getElementById('work-product-popover')) {
                Rally.ui.popover.PopoverFactory.bake({
                    field: 'WorkProduct',
                    target: this.getEl().down('.formatted-id-link'),
                    type: this.value._type,
                    oid: this.value.ObjectID,
                    context: this.getContext()
                });
            }
        },

        destroy: function() {
            if(this._delayedTask) {
                this._delayedTask.cancel();
            }
        }
    });
})();

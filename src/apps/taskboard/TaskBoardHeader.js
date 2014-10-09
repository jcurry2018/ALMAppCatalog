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

        afterRender: function() {
            var formattedIdLinkEl = this.getEl().down('.formatted-id-link');
            if (formattedIdLinkEl){
                formattedIdLinkEl.on('mouseenter', this._showWorkProductPopover, this);
            }
            this.callParent(arguments);
        },

        beforeDestroy: function() {
            var formattedIdLinkEl = this.getEl().down('.formatted-id-link');
            if (formattedIdLinkEl){
                formattedIdLinkEl.un('mouseenter', this._showWorkProductPopover, this);
            }
            this.callParent(arguments);
        },

        _showWorkProductPopover: function() {
            if (!Ext.getElementById('work-product-popover')) {
                Rally.ui.popover.PopoverFactory.bake({
                    field: 'WorkProduct',
                    target: this.getEl().down('.formatted-id-link'),
                    type: this.value._type,
                    oid: this.value.ObjectID,
                    context: this.getContext()
                });
            }
        }
    });
})();

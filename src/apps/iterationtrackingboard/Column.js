(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.iterationtrackingboard.Column', {
        extend: 'Rally.ui.cardboard.Column',
        alias: 'widget.iterationtrackingboardcolumn',

        getStoreFilter: function(model) {
            var filters = [];
            Ext.Array.push(filters, this.callParent(arguments));
            if (model.elementName === 'HierarchicalRequirement' && this.context.getSubscription().StoryHierarchyEnabled) {
                filters.push({
                    property: 'DirectChildrenCount',
                    value: 0
                });
            }

            return filters;
        }
    });
})();

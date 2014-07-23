(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.mixin.CollapsableHeaderContainer', {
        _getCollapsableHeaderContainerConfig: function(config) {
            return Ext.apply({
                xtype: 'container',
                cls: 'roadmap-header-collapsable' + (this.ownerCardboard.showHeader ? '' : ' header-collapsed')
            }, config);
        }
    });
})();
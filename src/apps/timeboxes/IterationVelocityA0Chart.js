(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.timeboxes.IterationVelocityA0Chart', {
        extend: 'Ext.Component',
        alias: 'widget.rallyiterationvelocitya0chart',

        afterRender: function () {
            Ext.Ajax.request({
                url: Rally.environment.getServer().getContextPath() + '/charts/iterationVelocityChart.sp',
                success: function (response) {
                    if (!this.isDestroyed) {
                        this.update(response.responseText);
                        this.getEl().down('div').setStyle('border', 'none');
                        this.getEl().down('input').hide();
                    }
                },
                scope: this
            });
        }
    });
})();
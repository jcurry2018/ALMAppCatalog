(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.milestones.MilestonesApp', {
        extend: 'Rally.app.App',
        requires: [],

        launch: function() {
            var container = this.add({
                xtype: 'component',
                html: 'Milestones are awesome!',
                style: {
                    fontFamily: 'ComicSansMS',
                    fontSize: '100px',
                    color: 'magenta',
                    height: '100%'
                }
            });

            var color = Math.random() * 360;
            var goldenAngle = 360 * 0.618033988749895;

            setInterval(function () {
                var el = container.getEl();
                if (el) {
                    container.getEl().setStyle('color', 'hsla(' + color + ', 100%, 45%, 1)');
                    color = (color + goldenAngle) % 360;
                }
            }, 100);
        }
    });
})();
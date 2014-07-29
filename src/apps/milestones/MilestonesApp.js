(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.milestones.MilestonesApp', {
        extend: 'Rally.app.App',
        requires: [],

        launch: function() {

            this.add({xtype: 'component', html: '<div title="up up down down left right left right b a enter?">Milestones coming soon!</div>'});

            // TODO: Possibly delete all of this code. Maybe.

            var app = this;
            var easterEggTimeoutId;
            var easterEggContainer;
            var easterEggColor;

            function updateEasterEgg () {
                var goldenAngle = 360 * 0.618033988749895;
                var el = easterEggContainer.getEl();
                if (el) {
                    el.setStyle('color', 'hsla(' + easterEggColor + ', 100%, 45%, 1)');
                    easterEggColor = (easterEggColor + goldenAngle) % 360;
                }
            };

            var enableEasterEgg = function () {
                easterEggColor = Math.random() * 360;
                if (!easterEggContainer) {
                    easterEggContainer = app.add({
                        xtype: 'component',
                        html: 'Milestones are awesome!',
                        style: {
                            fontFamily: 'ComicSansMS',
                            fontSize: '100px',
                            color: 'magenta',
                            height: '100%'
                        }
                    });
                }
                if (!easterEggTimeoutId) {
                    easterEggTimeoutId = setInterval(updateEasterEgg, 100);
                }
            };

            var disableEasterEgg = function () {
                if (easterEggTimeoutId) {
                    clearTimeout(easterEggTimeoutId);
                    easterEggTimeoutId = null;
                }
                if (easterEggContainer) {
                    easterEggContainer.destroy();
                    easterEggContainer = null;
                }
            };

            this.on('destroy', disableEasterEgg);

            var currentKeyPresses = [];
            var code = _.map(['up', 'up', 'down', 'down', 'left', 'right', 'left', 'right', 'b', 'a', 'enter'], function (keyName) {
                return Ext.EventObject[keyName.toUpperCase()];
            });

            this.mon(Ext.getBody(), 'keydown', function (event) {
                currentKeyPresses.push(event.keyCode);
                if (!_.isEqual(currentKeyPresses, code.slice(0, currentKeyPresses.length))) {
                    currentKeyPresses = [];
                } else if (currentKeyPresses.length === code.length) {
                    enableEasterEgg();
                }
            });
        }
    });
})();

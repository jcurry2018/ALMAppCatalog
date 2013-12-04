(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', {
        extend: 'Rally.app.App',
        requires: ['Rally.apps.roadmapplanningboard.RoadmapPlanningBoardController'],
        cls: 'roadmapPlanningBoardApp',
        componentCls: 'app',

        launch: function () {
            this.controller = Ext.create('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardController', {
                context: this.context,
                containerConfig: {
                    height: this.getEl() ? this.getHeight() : undefined,
                    listeners: this._getBoardListeners()
                }
            });

            this.add(this.controller.createPlanningBoard());
        },

        _getBoardListeners: function () {
            if (Rally.BrowserTest) {
                return {
                    load: this._onRendered,
                    scope: this
                };
            }
            return null;
        },

        _onRendered: function () {
            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this);
            }
        }
    });
})();

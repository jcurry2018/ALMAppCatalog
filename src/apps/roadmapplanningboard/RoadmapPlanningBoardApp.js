(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', {
        extend: 'Rally.app.App',
        requires: ['Rally.apps.roadmapplanningboard.RoadmapPlanningBoardController'],
        cls: 'roadmapPlanningBoardApp',
        componentCls: 'app',

        launch: function () {
            this.controller = Ext.create('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardController', {
                context: this.context
            });

            this.add(this.controller.createPlanningBoard());
        }
    });
})();

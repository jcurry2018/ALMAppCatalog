(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.apps.roadmapplanningboard.RoadmapPlanningBoardContainer'
        ],
        cls: 'roadmapPlanningBoardApp',
        componentCls: 'app',

        launch: function () {
            var container = Ext.create('Rally.apps.roadmapplanningboard.RoadmapPlanningBoardContainer', {
                context: this.context,
                height: '100%',
                cardboardPlugins: [
                    {
                        ptype: 'rallyfixedheadercardboard'
                    }
                ]
            });

            this.add(container);
        }
    });
})();

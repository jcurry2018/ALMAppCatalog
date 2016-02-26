(function () {
	var Ext = window.Ext4 || window.Ext;

	Ext.define('Rally.apps.chartbuilder.milestoneburn.MilestoneBurnApp', {
		name: 'rally-cbchart-milestoneburn-app',
		extend: 'Rally.apps.chartbuilder.ChartPanelApp',
		chartType: 'milestone-burn'
	});
}());

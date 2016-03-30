(function () {
	var Ext = window.Ext4 || window.Ext;

	Ext.define('Rally.apps.chartbuilder.milestonecfd.MilestoneCfdApp', {
		name: 'rally-cbchart-milestonecfd-app',
		extend: 'Rally.apps.chartbuilder.ChartPanelApp',
		chartType: 'milestone-cumulative-flow'
	});
}());

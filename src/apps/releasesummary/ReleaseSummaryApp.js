(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.releasesummary.ReleaseSummaryApp', {
        extend: 'Rally.app.TimeboxScopedApp',
        alias: 'widget.releasesummaryapp',
        componentCls: 'releasesummary',
        requires: [
            'Rally.ui.grid.Grid',
            'Rally.app.plugin.Print'
        ],
        plugins: [{
            ptype: 'rallyappprinting'
        }],
        scopeType: 'release',
        supportsUnscheduled: false,

        launch: function() {
            this.add({
                xtype: 'component',
                itemId: 'release-info',
                tpl: [
                    '<div class="release-info"><p><b>About this release: </b><br />',
                    '<p class="release-notes">{notes}</p>',
                    'Additional information is available <a href="{detailUrl}" target="_top">here.</a></p></div>'
                ]
            });

            this.callParent(arguments);
        },

        onScopeChange: function(scope) {
            this._loadReleaseDetails(scope);

            if(!this.down('#story-grid')) {
                Rally.data.ModelFactory.getModels({
                    types: ['UserStory', 'Defect']
                }).then({
                    success: function(models) {
                        this._buildGrids(models);
                    },
                    scope: this
                });
            } else {
                this._refreshGrids();
            }
        },

        onNoAvailableTimeboxes: function() {
            var storyGrid = this.down('#story-grid'),
                defectGrid = this.down('#defect-grid'),
                releaseInfo = this.down('#release-info');

            if (storyGrid) {
                storyGrid.destroy();
            }
            if (defectGrid) {
                defectGrid.destroy();
            }
            if (releaseInfo) {
                releaseInfo.getEl().setHTML('');
            }
        },

        _buildGrids: function(models) {
            this.add(this._getGridConfig({
                    itemId: 'story-grid',
                    title: 'Stories',
                    enableBulkEdit: false,
                    store: Ext.create('Rally.data.wsapi.TreeStore', this._getStoreConfig({
                        model: models.UserStory,
                        parentTypes: [models.UserStory.typePath]
                    })),
                    listeners: {
                        storeload: function (store) {
                            this.down('#story-grid').setTitle('Stories: ' + store.getTotalCount());
                        },
                        scope: this
                    }
                })
            );

            this.add(this._getGridConfig({
                itemId: 'defect-grid',
                title: 'Defects',
                store: Ext.create('Rally.data.wsapi.TreeStore', this._getStoreConfig({
                    model: models.Defect,
                    parentTypes: [models.Defect.typePath]
                })),
                listeners: {
                    storeload: function(store) {
                        this.down('#defect-grid').setTitle('Defects: ' + store.getTotalCount());
                    },
                    scope: this
                }
            }));
        },

        _loadReleaseDetails: function(scope) {
            var release = scope.getRecord();
            if (release) {
                release.self.load(Rally.util.Ref.getOidFromRef(release), {
                    fetch: ['Notes'],
                    success: function(record) {
                        this.down('#release-info').update({
                            detailUrl: Rally.nav.Manager.getDetailUrl(release),
                            notes: record.get('Notes')
                        });
                    },
                    scope: this
                });
            }
        },

        _getStoreConfig: function(storeConfig) {
            return Ext.apply({
                autoLoad: true,
                context: this.getContext().getDataContext(),
                requester: this,
                fetch: ['FormattedID', 'Name', 'ScheduleState'],
                filters: [this.getContext().getTimeboxScope().getQueryFilter()],
                sorters: [{
                    property: 'Rank',
                    direction: 'ASC'
                }]
            }, storeConfig);
        },

        _getGridConfig: function(config) {
            return Ext.apply({
                xtype: 'rallytreegrid',
                style: {
                    width: '99%' //fix scrollbar issue, better way to do this?
                },
                showRowActionsColumn: false,
                columnCfgs: [
                    'FormattedID',
                    'Name',
                    'ScheduleState'
                ]
            }, config);
        },

        _refreshGrids: function() {
            var timeboxFilter = [this.getContext().getTimeboxScope().getQueryFilter()],
                defectGrid = this.down('#defect-grid'),
                storyGrid = this.down('#story-grid');
            defectGrid.store.clearFilter(true);
            storyGrid.store.clearFilter(true);
            storyGrid.store.filter(timeboxFilter);
            defectGrid.store.filter(timeboxFilter);
        },

        getOptions: function() {
            return [this.getPrintMenuOption({title: 'Release Summary App'})]; //from printable mixin
        }
    });
})();
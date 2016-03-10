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
        helpId: 247,
        scopeType: 'release',
        supportsUnscheduled: false,
        releaseInfoData: {},

        onScopeChange: function(scope) {
            this._loadReleaseDetails(scope);

            //this code recreates the grids on resize - should try not to do that
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
            var releaseInfoHeight = 69;
            var gridHeight = Math.max(150, Math.ceil(this._getAvailableGridHeight()/2)-Math.ceil(releaseInfoHeight/2));
            //need to set height here
            this.add({
                    xtype: 'component',
                    itemId: 'release-info',
                    height: releaseInfoHeight,
                    tpl: [
                        '<div class="release-info"><p><b>About this release: </b><br />',
                        '<p class="release-notes">{notes}</p>',
                        'Additional information is available <a href="{detailUrl}" target="_top">here.</a></p></div>'
                    ],
                    data: this.releaseInfoData
                }, this._getGridConfig({
                    itemId: 'story-grid',
                    title: 'Stories',
                    enableBulkEdit: false,
                    store: Ext.create('Rally.data.wsapi.TreeStore', this._getStoreConfig({
                        model: models.UserStory,
                        parentTypes: [models.UserStory.typePath]
                    })),
                    height: gridHeight,
                    listeners: {
                        storeload: function (store) {
                            this.down('#story-grid').setTitle('Stories: ' + store.getTotalCount());
                        },
                        scope: this
                    }
                }), this._getGridConfig({
                    itemId: 'defect-grid',
                    title: 'Defects',
                    store: Ext.create('Rally.data.wsapi.TreeStore', this._getStoreConfig({
                        model: models.Defect,
                        parentTypes: [models.Defect.typePath]
                    })),
                    height: gridHeight,
                    listeners: {
                        storeload: function(store) {
                            this.down('#defect-grid').setTitle('Defects: ' + store.getTotalCount());
                        },
                        scope: this
                    }
                })
            );
        },

        _getAvailableGridHeight: function() {
            var header = this.down('container[cls=header]');
            //there is 11 px of padding or something and I don't know where it is coming from
            return this.height - 11 - (header ? header.getHeight() : 0); //getHeight is expensive, so don't call unnecessarily
        },

        _loadReleaseDetails: function(scope) {
            var release = scope.getRecord();
            if (release) {
                release.self.load(Rally.util.Ref.getOidFromRef(release), {
                    fetch: ['Notes'],
                    success: function(record) {
                        this.releaseInfoData = {
                            detailUrl: Rally.nav.Manager.getDetailUrl(release),
                            notes: record.get('Notes')
                        };
                        var releaseInfo = this.down('#release-info');
                        if (releaseInfo) {
                            releaseInfo.update(this.releaseInfoData);
                        } //applied when adding the tpl
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
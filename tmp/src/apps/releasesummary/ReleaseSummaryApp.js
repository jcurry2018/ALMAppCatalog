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

        launch: function() {
            this.add(
                {
                    xtype: 'container',
                    itemId: 'releaseInfo',
                    tpl: [
                        '<div class="releaseInfo"><p><b>About this release: </b><br />',
                        '<p class="release-notes">{notes}</p>',
                        'Additional information is available <a href="{detailUrl}" target="_top">here.</a></p></div>'
                    ]
                },
                {
                    xtype: 'container',
                    itemId: 'stories',
                    items: [{
                        xtype: 'label',
                        itemId: 'story-title',
                        componentCls: 'gridTitle',
                        text: 'Stories:'
                    }]
                },
                {
                    xtype: 'container',
                    itemId: 'defects',
                    items: [{
                        xtype: 'label',
                        itemId: 'defect-title',
                        text: 'Defects:',
                        componentCls: 'gridTitle'
                    }]
                }
            );
            this.callParent(arguments);
        },

        onScopeChange: function(scope) {
            if(!this.models) {
                Rally.data.ModelFactory.getModels({
                    types: ['UserStory', 'Defect'],
                    success: function(models) {
                        this.models = models;
                        this._buildGrids();
                        this._loadReleaseDetails(scope);
                    },
                    scope: this
                });
            } else {
                this._refreshGrids();
                this._loadReleaseDetails(scope);
            }
        },

        _loadReleaseDetails: function(scope) {
            var release = scope.getRecord();
            if (release) {
                var releaseModel = release.self;

                releaseModel.load(Rally.util.Ref.getOidFromRef(release), {
                    fetch: ['Notes'],
                    success: function(record) {
                        this.down('#releaseInfo').update({
                            detailUrl: Rally.nav.Manager.getDetailUrl(release),
                            notes: record.get('Notes')
                        });
                    },
                    scope: this
                });
            }
        },

        _buildGrids: function() {
            var storyStoreConfig = this._getStoreConfig({
                model: this.models.UserStory,
                listeners: {
                    load: this._onStoriesDataLoaded,
                    scope: this
                }
            });
            this.down('#stories').add(this._getGridConfig({
                itemId: 'story-grid',
                model: this.models.UserStory,
                storeConfig: storyStoreConfig
            }));

            var defectStoreConfig = this._getStoreConfig({
                model: this.models.Defect,
                listeners: {
                    load: this._onDefectsDataLoaded,
                    scope: this
                }
            });
            this.down('#defects').add(this._getGridConfig({
                itemId: 'defect-grid',
                model: this.models.Defect,
                storeConfig: defectStoreConfig
            }));
        },

        _getStoreConfig: function(storeConfig) {
            return Ext.apply({
                autoLoad: true,
                fetch: ['FormattedID', 'Name', 'ScheduleState'],
                filters: [this.getContext().getTimeboxScope().getQueryFilter()],
                sorters: [{
                    property: 'FormattedID',
                    direction: 'ASC'
                }],
                pageSize: 25
            }, storeConfig);
        },


        _getGridConfig: function(config) {
            return Ext.apply({
                xtype: 'rallygrid',
                componentCls: 'grid',
                showRowActionsColumn: false,
                columnCfgs: [
                    'FormattedID',
                    {text: 'Name', dataIndex: 'Name', flex: 3},
                    {text: 'Schedule State', dataIndex: 'ScheduleState', flex: 1, renderer: function(value) {
                        return value;
                    }}
                ]
            }, config);
        },

        _refreshGrids: function() {
            var filter = [this.getContext().getTimeboxScope().getQueryFilter()];
            this.down('#defect-grid').filter(filter, true, true);
            this.down('#story-grid').filter(filter, true, true);
        },

        _onStoriesDataLoaded: function (store) {
            this.down('#story-title').update('Stories: ' + store.getTotalCount());
            this._storiesLoaded = true;
            this._fireReady();
        },

        _onDefectsDataLoaded: function (store) {
            this.down('#defect-title').update('Defects: ' + store.getTotalCount());
            this._defectsLoaded = true;
            this._fireReady();
        },

        _fireReady: function() {
            if(Rally.BrowserTest && this._storiesLoaded && this._defectsLoaded && !this._readyFired) {
                this._readyFired = true;
                Rally.BrowserTest.publishComponentReady(this);
            }
        },

        getOptions: function() {
            return [
                this.getPrintMenuOption({title: 'Release Summary App'}) //from printable mixin
            ];
        }
    });
})();
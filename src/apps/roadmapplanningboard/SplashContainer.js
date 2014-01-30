(function () {
    var Ext = window.Ext4 || window.Ext;

    /**
     * @private
     */
    Ext.define('Rally.apps.roadmapplanningboard.SplashContainer', {
        alias: 'widget.splashcontainer',
        extend: 'Ext.container.Container',
        requires: [
            'Rally.ui.carousel.Carousel',
            'Rally.data.PreferenceManager',
            'Rally.util.Help'
        ],
        cls: 'roadmap-splash-container',
        itemId: 'roadmap-splash-container',

        layout: {
            type: 'vbox',
            pack: 'center',
            align: 'center'
        },

        config: {
            isAdmin: false,
            showGotIt: true
        },

        statics: {
            PREFERENCE_NAME: 'RoadmapSplashPreference',

            loadPreference: function () {
                return Rally.data.PreferenceManager.load({
                    filterByUser: true,
                    filterByName: Rally.apps.roadmapplanningboard.SplashContainer.PREFERENCE_NAME
                });
            }
        },

        initComponent: function () {
            this.callParent(arguments);

            this.add([
                {
                    xtype: 'rallycarousel',
                    itemId: 'carousel',
                    showHeader: true,
                    headerConfig: {
                        title: 'Introducing the new Roadmap Planning Board!',
                        text: 'Create realistic feature roadmap plans that consider feature size, business value, development risk, and overall development capability'
                    },

                    carouselItems: [
                        {
                            xtype: 'component',
                            cls: 'start-screen-1',
                            width: 650,
                            height: 380
                        },
                        {
                            xtype: 'component',
                            cls: 'start-screen-2',
                            width: 650,
                            height: 380
                        },
                        {
                            xtype: 'component',
                            cls: 'start-screen-3',
                            width: 650,
                            height: 380
                        },
                        {
                            xtype: 'component',
                            cls: 'start-screen-4',
                            width: 650,
                            height: 380
                        },
                        {
                            xtype: 'component',
                            cls: 'start-screen-5',
                            width: 650,
                            height: 380
                        }
                    ]
                }
            ]);
            if (this.isAdmin) {
                this.down('#carousel').down('#carousel-header').add([
                    {
                        xtype: 'container',
                        layout: {
                            type: 'vbox',
                            align: 'center'
                        },
                        items: [{
                            xtype: 'rallybutton',
                            buttonAlign: 'center',
                            text: 'Get Started!',
                            itemId: 'get-started',
                            cls: 'primary button medium harmonize-btn',
                            margin: '20 0 20 0',
                            handler: function () {
                                this.fireEvent('getstarted', this);
                            },
                            scope: this
                        }]
                    }
                ]);
            }

            if (this.showGotIt) {
                this.down('#carousel').down('#carousel-footer').add([
                    {
                        xtype: 'rallybutton',
                        text: 'Got it!',
                        itemId: 'got-it',
                        cls: 'primary button medium harmonize-btn',
                        handler: function () {
                            this._savePreference();
                            this.fireEvent('gotit', this);
                        },
                        scope: this
                    }
                ]);
            }
            this.down('#carousel').down('#carousel-footer').add([
                {
                    xtype: 'rallybutton',
                    text: 'Learn more',
                    itemId: 'learn-more',
                    cls: 'secondary button medium harmonize-btn',
                    href: Rally.util.Help.getHelpUrl({id: 280})
                }
            ]);

            this.addEvents(
                'gotit',
                'getstarted'
            );
        },

        _savePreference: function () {
            var settings = {};
            settings[Rally.apps.roadmapplanningboard.SplashContainer.PREFERENCE_NAME] = true;
            return Rally.data.PreferenceManager.update({
                settings: settings,
                filterByUser: true,
                filterByName: Rally.apps.roadmapplanningboard.SplashContainer.PREFERENCE_NAME
            });
        }
    });
})();

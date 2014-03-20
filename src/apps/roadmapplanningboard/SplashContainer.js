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
            showGetStarted: false,
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

            var carouselItems = _.times(5, function (index) {
                return {
                    xtype: 'component',
                    cls: 'start-screen start-screen-' + (index + 1),
                    width: 655,
                    height: 385
                };
            });

            var headerText = 'Create realistic feature roadmap plans that consider feature size, business value, development risk, and overall development capacity.';
            var helpLink = Rally.util.Help.getLinkTag({
                id: 281,
                text: 'What about my Release?'
            });

            this.add([
                {
                    xtype: 'rallycarousel',
                    itemId: 'carousel',
                    showHeader: true,
                    headerConfig: {
                        title: 'Introducing the new Roadmap Planning Board!',
                        text: headerText + ' ' + helpLink
                    },

                    carouselItems: carouselItems
                }
            ]);

            var footer = this.down('#carousel').down('#carousel-footer');

            if (this.showGetStarted || this.showGotIt) {
                footer.add({
                    xtype: 'rallybutton',
                    text: this.showGetStarted ? 'Get Started!' : 'Got it!',
                    itemId: this.showGetStarted ? 'get-started' : 'got-it',
                    cls: 'splash-action-button primary medium',
                    handler: function () {
                        this._savePreference();
                        this.fireEvent(this.showGetStarted ? 'getstarted' : 'gotit', this);
                    },
                    scope: this
                });
            }

            footer.add({
                xtype: 'rallybutton',
                text: 'Learn more',
                itemId: 'learn-more',
                cls: 'secondary medium',
                href: Rally.util.Help.getHelpUrl({id: 280})
            });

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

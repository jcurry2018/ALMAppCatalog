(function() {
    var Ext = window.Ext4 || window.Ext;
    Ext.define('Rally.apps.timeboxes.NewPageNoticePopover', {
        extend: 'Rally.ui.dialog.Dialog',
        requires: [
            'Rally.ui.Button',
            'Rally.ui.carousel.Carousel',
            'Rally.ui.popover.NewPopoverViewController'
        ],
        controller: 'Rally.ui.popover.NewPopoverViewController',

        autoCenter: true,
        autoShow: true,
        closable: true,
        cls: 'new-iteration-status-page-dialog splash-dialog',
        height: 500,
        layout: 'fit',
        modal: true,
        placement: 'bottom',
        showChevron: false,
        title: 'The new Timeboxes page',
        width: 600,

        constructor: function (config) {
            this.initConfig(config);
            this.callParent(arguments);

            this.center();
        },

        initComponent:function () {
            this.callParent(arguments);

            var contextPath =  Rally.environment.getServer().getContextPath();
            this.add({
                xtype: 'rallycarousel',
                showHeader: false,
                showDots: true,
                infiniteScroll: false,
                height: 435,
                width: 525,
                layout: {
                    type: 'vbox',
                    align: 'center'
                },
                carouselItems: [
                    {
                        xtype: 'component',
                        cls: 'carousel-item',
                        html: "<div class='carousel-header'><div class='title' style='display: block;'><span class='title-text'>Welcome to the new Timeboxes page!</span></div></div>"+
                            "<img class='carousel-pane-animation' style='margin-left: 12px;' src='" + contextPath + "/js-lib/app-catalog/src/apps/timeboxes/images/welcome-page-1.png' />" +
                            "<div class='carousel-pane-text'>We’ve updated and combined the Iterations, Releases, and Milestones pages into a single new page that is more powerful and easier to use. </div>"
                    },
                    {
                        xtype: 'component',
                        cls: 'carousel-item',
                        html: "<div class='carousel-header'><div class='title' style='display: block;'><span class='title-text'>Select your Timebox</span></div></div>" +
                            "<img class='carousel-pane-animation' style='margin-left: 12px;' src='" + contextPath + "/js-lib/app-catalog/src/apps/timeboxes/images/welcome-page-2.png' />" +
                            "<div class='carousel-pane-text'>Use the selector next to the page title to choose the timebox type you would like to work with. </div>"
                    },
                    {
                        xtype: 'container',
                        cls: 'carousel-item',
                        layout: 'anchor',
                        items: [
                            {
                                xtype: 'component',
                                html: "<div class='carousel-header'><div class='title' style='display: block;'><span class='title-text'>Customize your view</span></div></div>" +
                                    "<img class='carousel-pane-animation' style='margin-left: 12px;' src='" + contextPath + "/js-lib/app-catalog/src/apps/timeboxes/images/welcome-page-3.png' />" +
                                    "<div class='carousel-pane-text'>Filter and customize your view to better fit how you work.</div>"
                            },
                            {
                                xtype: 'rallybutton',
                                text: 'Got it!',
                                cls: 'primary medium got-it',
                                handler: this._onButtonClick,
                                scope: this
                            }
                        ]
                    }
                ]
            });
        },

        afterRender: function () {
            this.callParent(arguments);

            Ext.fly(Ext.DomQuery.selectNode('html')).addCls('no-overflow');
        },

        onDestroy: function() {
            Ext.fly(Ext.DomQuery.selectNode('html')).removeCls('no-overflow');
            this.callParent(arguments);
        },

        _onButtonClick: function() {
            this.close();
            this.destroy();
        }
    });
})();
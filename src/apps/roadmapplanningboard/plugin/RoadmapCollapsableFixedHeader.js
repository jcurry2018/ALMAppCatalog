(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.plugin.RoadmapCollapsableFixedHeader', {
        alias: 'plugin.rallyroadmapcollapsableheader',

        extend: 'Rally.ui.cardboard.plugin.FixedHeader',

        requires: [
            'Rally.data.PreferenceManager'
        ],

        statics: {
            PREFERENCE_NAME: 'roadmapplanningboard.header.expanded'
        },

        clientMetrics: [
            {
                method: '_toggleHeaders',
                descriptionProperty: 'getClickActionDescription'
            }
        ],

        init: function (cmp) {
            this.originalRenderColumns = cmp.renderColumns;
            cmp.renderColumns = Ext.bind(this.renderColumns, this);

            this.callParent(arguments);
        },

        destroy: function () {
            this._destroyHeaderButton();
        },

        renderColumns: function () {
            this._readPreference().then({
                success: function () {
                    this.originalRenderColumns.call(this.cmp);
                    this._drawHeaderToggle();
                },
                scope: this
            });
        },

        _drawHeaderToggle: function () {
            this._destroyHeaderButton();

            this.headerToggleButton = Ext.create('Rally.ui.Button', {
                cls: 'header-toggle-button',
                listeners: {
                    click: this._toggleHeaders,
                    scope: this
                },
                renderTo: Ext.getBody().down('.fixed-header-card-board-header-container')
            });

            this._updateHeaderToggleButton();
        },

        _updateHeaderToggleButton: function () {
            if(this.cmp.showHeader) {
                this._addHeaderToggleTooltip('Collapse header');
                this.headerToggleButton.setIconCls('icon-chevron-up');
            } else {
                this._addHeaderToggleTooltip('Expand header');
                this.headerToggleButton.setIconCls('icon-chevron-down');
            }

            this.headerToggleButton.show();
        },

        _addHeaderToggleTooltip: function(content) {
            if (this.headerToggleTooltip) {
                this.headerToggleTooltip.destroy();
            }

            this.headerToggleTooltip = Ext.create('Rally.ui.tooltip.ToolTip', {
                target: this.headerToggleButton.getEl(),
                showDelay: 1000,
                html: '<span>' + content + '</span>',
                anchorOffset: 6,
                mouseOffset: [0, -8]
            });
        },

        _toggleHeaders: function () {
            this.cmp.showHeader = !this.cmp.showHeader;
            this.headerToggleButton.hide();
            this._updateHeaderToggleButton();
            this._updateHeaderContainers().then({
                success: function () {
                    this.cmp.fireEvent('headersizechanged', this.cmp);
                },
                scope: this
            });
            this._savePreference(this.cmp.showHeader);
        },

        _savePreference: function(val) {
            var settings = {},
                name = Rally.apps.roadmapplanningboard.PlanningBoard.PREFERENCE_NAME;

            settings[name] = val;
            return Rally.data.PreferenceManager.update({
                settings: settings,
                filterByUser: true,
                filterByName: name
            });
        },

        _readPreference: function() {
            return Rally.data.PreferenceManager.load({
                filterByUser: true,
                filterByName: Rally.apps.roadmapplanningboard.PlanningBoard.PREFERENCE_NAME
            }).then({
                success: function (result) {
                    var name = Rally.apps.roadmapplanningboard.PlanningBoard.PREFERENCE_NAME;
                    this.cmp.showHeader = !result.hasOwnProperty(name) || result[name] === 'true';
                },
                scope: this
            });
        },

        getClickActionDescription: function () {
            return 'Roadmap header expansion toggled from [' + !this.cmp.showHeader + '] to [' + this.cmp.showHeader + ']';
        },

        _updateHeaderContainers: function () {
            var headerContainers = _.map(this.cmp.getEl().query('.roadmap-header-collapsable'), Ext.get);
            var promises = _.map(headerContainers, this._toggleHeaderContainer, this);

            return Deft.Promise.all(promises);
        },

        _toggleHeaderContainer: function (el) {
            var deferred = new Deft.Deferred();

            el.removeCls('header-collapsed');
            el.animate({
                duration: this.cmp.showHeader ? 1000 : 250,
                to: {
                    height: this.cmp.showHeader ? '100%' : '0',
                    opacity: this.cmp.showHeader ? 1.0 : 0
                },
                listeners: {
                    afteranimate: function() {
                        if (!this.cmp.showHeader) {
                            el.addCls('header-collapsed');
                        }
                        deferred.resolve();
                    },
                    scope: this
                }
            });

            return deferred.promise;
        },

        _destroyHeaderButton: function () {
            if(this.headerToggleButton) {
                this.headerToggleButton.destroy();
            }
        }
    });
})();
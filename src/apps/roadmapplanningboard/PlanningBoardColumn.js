(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.PlanningBoardColumn', {
        extend: 'Rally.ui.cardboard.Column',
        alias: 'widget.planningboardcolumn',

        mixins: {
            maskable: 'Rally.ui.mask.Maskable'
        },
        requires: [
            'Rally.apps.roadmapplanningboard.plugin.OrcaColumnDropController'
        ],

        config: {
            /**
             * @cfg {Object} Object containing Names and TypePaths of the lowest level portfolio item (eg: 'Feature') and optionally its parent (eg: 'Initiative')
             */
            typeNames: {},
            dropControllerConfig: {
                ptype: 'orcacolumndropcontroller'
            },
            cardConfig: {
                showIconsAndHighlightBorder: true,
                showPlusIcon: false,
                showColorIcon: true,
                showGearIcon: true,
                showReadyIcon: false,
                showBlockedIcon: false,
                showEditMenuItem: true,
                showCopyMenuItem: false,
                showSplitMenuItem: false,
                showDeleteMenuItem: true,
                showAddChildMenuItem: false,
                showRankMenuItems: false
            }
        },

        constructor: function (config) {
            this.mergeConfig(config);
            this.context = this.context || Rally.environment.getContext();
            if (!this.config.context) {
                this.config.context = this.context;
            }

            this.callParent([this.config]);
        },

        initComponent: function () {
            if (!this.typeNames.child || !this.typeNames.child.name) {
                throw 'typeNames must have a child property with a name';
            }

            this.callParent(arguments);

            this.on('beforerender', function () {
                var cls = 'planning-column';
                _.invoke(this.getContentCellContainers(), 'addCls', cls);
                return this.getColumnHeaderCell().addCls(cls);
            }, this, {
                single: true
            });
        },

        isMatchingRecord: function () {
            return true;
        },

        _getProgressBarHtml: function () {
            return '<div></div>';
        },

        findCardInfo: function (searchCriteria, includeHiddenCards) {
            var card, index, _i, _len, _ref;

            searchCriteria = searchCriteria.get && searchCriteria.getId() ? searchCriteria.getId() : searchCriteria;
            _ref = this.getCards(includeHiddenCards);
            for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
                card = _ref[index];
                if (card.getRecord().getId() === searchCriteria || card.getEl() === searchCriteria || card.getEl() === Ext.get(searchCriteria)) {
                    return {
                        record: card.getRecord(),
                        index: index,
                        card: card
                    };
                }
            }
            return null;
        },

        destroy: function () {
            var plugin, _i, _len, _ref;

            _ref = this.plugins;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                plugin = _ref[_i];
                if (plugin !== null) {
                    plugin.destroy();
                }
            }
            return this.callParent(arguments);
        },

        getColumnIdentifier: function () {
            Ext.Error.raise('Need to override this to ensure unique identifier for persistence');
        },

        refreshRecord: function (record, callback) {
            this.store.setFilter(this.getStoreFilter());
            return this.callParent(arguments);
        }
    });
})();

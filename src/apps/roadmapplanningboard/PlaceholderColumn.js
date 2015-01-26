(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.PlaceholderColumn', {
        extend: 'Ext.Component',
        alias: 'widget.cardboardplaceholdercolumn',

        requires: [ 'Rally.ui.cardboard.Column', 'Rally.ui.cardboard.ColumnHeader' ],

        mixins: [ 'Rally.apps.roadmapplanningboard.mixin.CollapsableHeaderContainer' ],

        afterRender: function () {
            this.drawHeader();

            this.fireEvent('ready', this);
        },

        drawHeader: function () {
            var config = {
                renderTo: Ext.get(this.headerCell)
            };

            Ext.fly(this.headerCell).addCls('planning-column');
            this.columnHeader = Ext.widget(Ext.merge(config, this.columnHeaderConfig));

            // Add a couple of containers to match the structure of the timeframe planning column header
            this.columnHeader.add(this._getCollapsableHeaderContainerConfig(this._getTemplateConfig()));
        },

        _getTemplateConfig: function() {
            return {
                tpl: [
                    '<div class="timeframeDatesContainer"></div>',
                    '<div class="progress-bar-background"></div>',
                    '<div class="theme_container"></div>'
                ],
                data: {}
            };
        },

        getColumnHeader: function() {
            return this.columnHeader;
        },

        getColumnHeaderCell: function () {
            return Ext.get(this.headerCell);
        },

        getContentCell: function () {
            return Ext.get(this.contentCell);
        },

        getCards: function () {
            return [];
        },

        findCardInfo: function () {
            return null;
        },

        isMatchingRecord: function () {
            return false;
        },

        isVisible: function () {
            return true;
        },

        refresh: function () {
            this.fireEvent('ready', this);
            return null;
        },

        getHeaderTitle: function () {
            return this.columnHeader.down('#headerTitle');
        },

        getMinWidth: function () {
            return Rally.ui.cardboard.Column.prototype.getMinWidth();
        },

        filter: Ext.emptyFn,

        onRowAdded: Ext.emptyFn
    });
})();

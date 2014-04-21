(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.PlaceholderColumn', {
        extend: 'Ext.Component',
        alias: 'widget.cardboardplaceholdercolumn',

        requires: [
            'Rally.ui.cardboard.ColumnHeader'
        ],

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
            this.columnHeader.add({
                xtype: 'container',
                tpl: [
                    '<div class="progress-bar-background"></div>'
                ],
                data: {}
            });
            this.columnHeader.add({
                xtype: 'container',
                tpl: [
                    '<div class="theme_container"></div>'
                ],
                data: {}
            });
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

        refresh: function () {
            this.fireEvent('ready', this);
            return null;
        },

        getHeaderTitle: function () {
            return this.columnHeader.down('#headerTitle');
        }

    });

})();

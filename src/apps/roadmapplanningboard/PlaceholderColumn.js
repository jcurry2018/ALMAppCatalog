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

            this.columnHeader.add({
                xtype: 'container',
                tpl: [
                    '<div class="progress-bar-background"></div>',
                    '<div class="theme_container"></div>'
                ],
                data: {}
            });
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

        getHeaderTitle: function () {
            return this.columnHeader.down('#headerTitle');
        }

    });

})();

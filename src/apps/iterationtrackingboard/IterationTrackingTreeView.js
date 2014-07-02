(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.iterationtrackingboard.IterationTrackingTreeView', {
        extend: 'Rally.ui.grid.TreeView',
        alias: 'widget.rallyiterationtrackingtreeview',

        /**
         * Sizes the passed header to fit the max content width.
         * @param {Ext.grid.column.Column/Number} header The header (or index of header) to auto size.
         * @param {Boolean} allowWrapping Should allow content to wrap when finding width.  Defaults to true.
         */
        autoSizeColumn: function(header, allowWrapping, allowShrinking) {
            allowWrapping = allowWrapping !== false;
            allowShrinking = allowShrinking !== false;

            if (Ext.isNumber(header)) {
                header = this.getGridColumns()[header];
            }

            if (header) {
                if (header.isGroupHeader) {
                    header.autoSize();
                    return;
                }
                delete header.flex;

                var newWidth = this.getContentWidth(header, allowWrapping);
                if (!allowShrinking) {
                    newWidth = Math.max(header.getWidth(), newWidth);
                }

                header.setWidth(newWidth);
            }
        },

        /**
         * Returns the max contentWidth of the header's text and all cells in the grid under this header.
         * @param {Ext.grid.column.Column} header The header for which to calculate content width
         * @param {Boolean} allowWrapping Should allow content to wrap when finding width.  Defaults to true.
         */
        getContentWidth: function(header, allowWrapping) {
            allowWrapping = allowWrapping !== false;

            var me = this,
                cells = me.el.query(header.getCellInnerSelector()),
                originalWidth = header.getWidth(),
                i = 0,
                ln = cells.length,
                columnSizer = me.body.select(me.getColumnSizerSelector(header)),
                max = Math.max,
                widthAdjust = 4,
                minAllowedWidth = 40,
                maxWidth;

            if (ln > 0) {
                if (Ext.supports.ScrollWidthInlinePaddingBug) {
                    widthAdjust += me.getCellPaddingAfter(cells[0]);
                }
                if (me.columnLines) {
                    widthAdjust += Ext.fly(cells[0].parentNode).getBorderWidth('lr');
                }
                if (Ext.isGecko || (Ext.isWindows && Ext.isSafari)) {
                    widthAdjust += 4;
                }
            }

            // Set column width to 1px so we can detect the content width by measuring scrollWidth
            columnSizer.setWidth(1);

            // We are about to measure the offsetWidth of the textEl to determine how much
            // space the text occupies, but it will not report the correct width if the titleEl
            // has text-overflow:ellipsis.  Set text-overflow to 'clip' before proceeding to
            // ensure we get the correct measurement.
            header.titleEl.setStyle('text-overflow', 'clip');

            // Allow for padding round text of header
            maxWidth = header.textEl.dom.offsetWidth + header.titleEl.getPadding('lr');

            // revert to using text-overflow defined by the stylesheet
            header.titleEl.setStyle('text-overflow', '');

            var cell, cellEl;
            for (; i < ln; i++) {

                cell = cells[i];
                cellEl = Ext.fly(cell);

                if (!allowWrapping) {
                    cellEl.setStyle('text-overflow', 'clip');
                    cellEl.setStyle('white-space', 'nowrap');
                    cellEl.setStyle('height', '20px');
                }

                maxWidth = max(maxWidth, cell.scrollWidth);

                if (!allowWrapping) {
                    cellEl.setStyle('height', '');
                    cellEl.setStyle('white-space', '');
                    cellEl.setStyle('text-overflow', '');
                }
            }

            // in some browsers, the "after" padding is not accounted for in the scrollWidth
            maxWidth += widthAdjust;

            maxWidth = max(maxWidth, minAllowedWidth);

            // Set column width back to original width
            columnSizer.setWidth(originalWidth);

            return maxWidth;
        }
    });
})();
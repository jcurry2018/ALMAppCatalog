(function() {
    var Ext = window.Ext4 || window.Ext;

    /**
     * @private
     * Allows the Roadmap Planning Board CardBoard to be scrolled forwards and backwards
     */
    Ext.define('Rally.apps.roadmapplanningboard.plugin.RoadmapScrollable', {
        alias: 'plugin.rallytimeframescrollablecardboard',
        extend: 'Rally.ui.cardboard.plugin.Scrollable',

        requires: [
            'Rally.apps.roadmapplanningboard.PlaceholderColumn'
        ],

        /**
         * @cfg {Number} timeframeColumnCount The number of timeframe columns
         */
        timeframeColumnCount: 4,

        /**
         * @cfg {String} columnConfig The xtype of the columns created if the available columns is less than {Rally.apps.roadmapplanningboard.plugin.RoadmapScrollable#timeframeColumnCount}
         */
        columnConfig: {
            xtype: 'cardboardplaceholdercolumn'
        },

        init: function (cmp) {
            this.originBuildColumns = cmp.buildColumns;
            cmp.buildColumns = Ext.bind(this.buildColumns, this);

            this.originDrawAddNewColumnButton = cmp.drawAddNewColumnButton;
            cmp.drawAddNewColumnButton = Ext.bind(this.drawAddNewColumnButton, this);
            cmp.addNewColumn = Ext.bind(this.addNewColumn, this);

            this.callParent(arguments);
        },

        drawAddNewColumnButton: function () {
            if (this._isForwardsButtonHidden()) {
                this.originDrawAddNewColumnButton.call(this.cmp);
            }
        },

        /**
         *
         * @param store
         */
        buildColumns: function (store) {
            var columns = this.originBuildColumns.call(this.cmp, store);

            this.backlogColumn = columns[0];
            this.scrollableColumns = columns.slice(1);
            // add an index to each column for tracking
            _.map(this.scrollableColumns, function (column, index) {
                column.index = index;
                return column;
            });

            this.cmp.columns = [this.backlogColumn].concat(this._getVisibleColumns(this._getPresentColumns(this.scrollableColumns)));
            return this.cmp.columns;
        },

        _getPresentColumns: function (columns) {
            var now = new Date();
            var format = 'Y-m-d';

            this.presentColumns = this.presentColumns || _.filter(columns, function (column) {
                return Ext.Date.format(column.timeframeRecord.get('endDate'), format) >= Ext.Date.format(now, format);
            }, this);

            return this.presentColumns;
        },

        _getVisibleColumns: function (presentColumns) {
            if (presentColumns.length < this.timeframeColumnCount) {
                var placeholderColumns = _.map(_.range(this.timeframeColumnCount - presentColumns.length), function (index) {
                    return _.extend({ index: index + this.scrollableColumns.length}, this.columnConfig);
                }, this);

                this.scrollableColumns = this.scrollableColumns.concat(placeholderColumns);
                return presentColumns.concat(placeholderColumns);
            } else {
                return _.first(presentColumns, this.timeframeColumnCount);
            }
        },

        _isBackwardsButtonHidden: function () {
            return this.getFirstVisibleScrollableColumn().index === 0;
        },

        _isForwardsButtonHidden: function () {
            return this.getLastVisibleScrollableColumn().index === this.scrollableColumns.length - 1;
        },

        _scroll: function (forwards) {
            var insertNextToColumn = this._getInsertNextToColumn(forwards);
            var newIndex = _.indexOf(this.cmp.getColumns(), insertNextToColumn);
            var newlyVisibleColumn = this.scrollableColumns[insertNextToColumn.index + (forwards ? 1 : -1)];

            var column = this._drawColumn(this._getColumnToRemove(forwards), newlyVisibleColumn, insertNextToColumn, newIndex, forwards);

            this.cmp.fireEvent('scroll', this.cmp);

            return column;
        },

        _drawColumn: function (removingColumn, newColumn, nextToColumn, index, forwards) {

            var columnEls = this.cmp.createColumnElements(forwards ? 'after' : 'before', nextToColumn);
            this.cmp.destroyColumn(removingColumn);
            var column = this.cmp.addColumn(newColumn, index);
            this.cmp.renderColumn(column, columnEls);
            column.on('ready', this._onNewlyAddedColumnReady, this, {single: true});
            this.cmp.drawThemeToggle();
            this.drawAddNewColumnButton();
            this._afterScroll();

            return column;
        },


        addNewColumn: function (columnConfig) {
            var placeHolderColumn = this._getFirstPlaceholderColumn();
            if (placeHolderColumn) {
                columnConfig.index = placeHolderColumn.index;
                this.scrollableColumns[columnConfig.index] = columnConfig;

                return this._drawColumn(placeHolderColumn, columnConfig, placeHolderColumn, columnConfig.index, false);

            } else {
                columnConfig.index = this.scrollableColumns.length;
                this.scrollableColumns.push(columnConfig);
                return this._scroll(true);
            }
        },

        _getFirstPlaceholderColumn: function () {
            return _.find(this.getScrollableColumns(), function (column) {
                return column.xtype === 'cardboardplaceholdercolumn';
            });
        },

        _onNewlyAddedColumnReady: function () {
            this.cmp.applyLocalFilters();
        },

        _sizeButtonToColumnHeader: function(button, column){
            var columnHeaderHeight = column.getHeaderTitle().getHeight();

            button.getEl().setHeight(columnHeaderHeight);
        },

        getFirstVisibleScrollableColumn: function () {
            return this.getScrollableColumns()[0];
        },

        getLastVisibleScrollableColumn: function () {
            return _.last(this.getScrollableColumns());
        },

        getScrollableColumns: function () {
            return this.cmp.getColumns().slice(1);
        }
    });
})();
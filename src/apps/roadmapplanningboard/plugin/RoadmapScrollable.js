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

        currentTimeframeIndex: 0,

        /**
         * @cfg {String} columnConfig The xtype of the columns created if the available columns is less than {Rally.apps.roadmapplanningboard.plugin.RoadmapScrollable#timeframeColumnCount}
         */
        columnConfig: {
            xtype: 'cardboardplaceholdercolumn'
        },

        init: function (cmp) {
            this.originalBuildColumns = cmp.buildColumns;
            cmp.buildColumns = Ext.bind(this.buildColumns, this);

            this.originalDrawAddNewColumnButton = cmp.drawAddNewColumnButton;
            cmp.drawAddNewColumnButton = Ext.bind(this.drawAddNewColumnButton, this);
            cmp.addNewColumn = Ext.bind(this.addNewColumn, this);

            this.originalDestroyColumn = cmp.destroyColumn;
            cmp.destroyColumn = Ext.bind(this.destroyColumn, this);

            this.originalOnColumnDateRangeChange = cmp._onColumnDateRangeChange;
            cmp._onColumnDateRangeChange = Ext.bind(this._onColumnDateRangeChange, this);

            this.callParent(arguments);
        },

        drawAddNewColumnButton: function () {
            if (this._isForwardsButtonHidden()) {
                this.originalDrawAddNewColumnButton.call(this.cmp);
            }
        },

        /**
         *
         * @param store
         */
        buildColumns: function (options) {
            options = options || {};

            var columns = this.originalBuildColumns.call(this.cmp, options);

            this.backlogColumn = columns[0];
            this.scrollableColumns = columns.slice(1);

            this._sortColumns();

            this.currentTimeframeIndex = this._getIndexOfFirstColumnToShow(options.firstTimeframe);

            this._addPlaceholderColumns();

            if (options.render) {
                this._hideColumns();
                this._syncColumns();
            } else {
                this.cmp.columns = [this.backlogColumn].concat(this._getColumnsToShow());
            }

            return this.cmp.columns;
        },

        _onColumnDateRangeChange: function (updatedColumn) {
            this._sortColumns();

            var columnMovedOffBoard = !_.some(this._getColumnsToShow(), function (column) {
                return column.timeframeRecord && column.timeframeRecord.getId() === updatedColumn.timeframeRecord.getId();
            });

            if (columnMovedOffBoard) {
                this.currentTimeframeIndex = updatedColumn.index; // Scroll to updated column
            }

            this._hideColumn(updatedColumn);
            this._syncColumns();

            this.originalOnColumnDateRangeChange.call(this.cmp, updatedColumn);
        },

        _sortColumns: function () {
            this.scrollableColumns.sort(function (columnA, columnB) {
                var timeframeA = columnA.timeframeRecord;
                var timeframeB = columnB.timeframeRecord;

                if (!timeframeA && !timeframeB) {
                    return 0;
                } else if (!timeframeA) {
                    return 1;
                } else if (!timeframeB) {
                    return -1;
                }

                return timeframeA.get('endDate') > timeframeB.get('endDate') ? 1 : -1;
            });

            this._reindexColumns();
        },

        _getIndexOfFirstColumnToShow: function (firstTimeframe) {
            var firstColumnToShow;

            if (firstTimeframe) {
                firstColumnToShow = this._getColumnForTimeframe(firstTimeframe);
            }

            if (!firstColumnToShow) {
                firstColumnToShow = this._getFirstPresentColumn() || this._getMostRecentPastColumn();
            }

            return firstColumnToShow.index || 0;
        },

        _getColumnForTimeframe: function (timeframe) {
            return _.find(this.scrollableColumns, function (column) {
                return column.timeframeRecord && column.timeframeRecord.getId() === timeframe.getId();
            });
        },

        _getMostRecentPastColumn: function () {
            return _.max(this.scrollableColumns, function (column) {
                return column.timeframeRecord && column.timeframeRecord.get('endDate');
            });
        },

        _getFirstPresentColumn: function () {
            var now = new Date();
            var format = 'Y-m-d';

            return _.find(this.scrollableColumns, function (column) {
                return column.timeframeRecord && Ext.Date.format(column.timeframeRecord.get('endDate'), format) >= Ext.Date.format(now, format);
            });
        },

        _isBackwardsButtonHidden: function () {
            return this.getFirstVisibleScrollableColumn().index === 0;
        },

        _isForwardsButtonHidden: function () {
            return this.getLastVisibleScrollableColumn().index === this.scrollableColumns.length - 1;
        },

        _syncColumns: function () {
            this._reindexColumns();
            this._adjustCurrentColumnIndex();
            this._updatePlaceholderColumns();
            this._renderScrollableColumns();
            this._renderButtons();
        },

        _scroll: function (forwards) {
            this.currentTimeframeIndex += forwards ? 1 : -1;

            this._syncColumns();

            this.cmp.fireEvent('scroll', this.cmp);
        },

        addNewColumn: function (columnConfig) {
            var placeHolderColumn = this._getFirstPlaceholderColumn();

            if (placeHolderColumn) {
                this.scrollableColumns.splice(placeHolderColumn.index, 0, columnConfig);
            } else {
                this.scrollableColumns.push(columnConfig);
                this.currentTimeframeIndex++;
            }

            this._syncColumns();

            return this._getVisibleColumn(columnConfig);
        },

        destroyColumn: function (columnToDelete) {
            this.scrollableColumns.splice(columnToDelete.index, 1);
            this._hideColumn(columnToDelete);
            this._syncColumns();
        },

        _hideColumn: function (column) {
            this.originalDestroyColumn.call(this.cmp, column);
        },

        _hideColumns: function () {
            _.each(this.cmp.getColumns().slice(1), function (column) {
                this._hideColumn(column);
            }, this);
        },

        _renderScrollableColumns: function () {
            _.each(this._getColumnsToHide(), function (column) {
                this._hideColumn(column);
            }, this);

            _.each(this._getColumnsToShow(), function (columnConfig) {
                var columnNotVisible = !this._getVisibleColumn(columnConfig);

                if (columnNotVisible) {
                    this._drawColumn(columnConfig);
                }
            }, this);
        },

        _drawColumn: function (columnConfig) {
            var displayIndex = this._getDisplayIndexForScrollableColumn(columnConfig);
            var column = this.cmp.addColumn(columnConfig, displayIndex);
            column.on('ready', this._onNewlyAddedColumnReady, this, {single: true});
            this.cmp.renderColumn(column, this._createColumnEls(displayIndex));
        },

        _shouldShowColumn: function (column) {
            return column.index >= this.currentTimeframeIndex && column.index < this.currentTimeframeIndex + this.timeframeColumnCount;
        },

        _getColumnsToShow: function () {
            return _.filter(this.scrollableColumns, function (column) {
                return this._shouldShowColumn(column);
            }, this);
        },

        _getColumnsToHide: function () {
            return _.filter(this.getScrollableColumns(), function (column) {
                return !this._shouldShowColumn(column);
            }, this);
        },

        _getVisibleColumn: function (columnConfig) {
            return _.find(this.getScrollableColumns(), function (visibleColumn) {
                if (columnConfig.planRecord && visibleColumn.planRecord) {
                    return columnConfig.planRecord.getId() === visibleColumn.planRecord.getId();
                }

                return _.has(columnConfig, 'placeholderId') && (columnConfig.placeholderId === visibleColumn.placeholderId);
            });
        },

        _createColumnEls: function (displayIndex) {
            return this.cmp.createColumnElements('after', this.cmp.getColumns()[displayIndex - 1]);
        },

        _updatePlaceholderColumns: function () {
            this._removePlaceholderColumns();
            this._addPlaceholderColumns();
        },

        _addPlaceholderColumns: function() {
            var numPlaceholderColumnsToAdd = this.currentTimeframeIndex + this.timeframeColumnCount - this.scrollableColumns.length;

            var placeholderColumns = _.times(numPlaceholderColumnsToAdd, function (index) {
                return Ext.merge({
                    placeholderId: index,
                    index: index + this.scrollableColumns.length
                }, this.columnConfig);
            }, this);

            this.scrollableColumns = this.scrollableColumns.concat(placeholderColumns);
        },

        _removePlaceholderColumns: function() {
            this.scrollableColumns = _.reject(this.scrollableColumns, function (column) {
                return this._isPlaceholderColumn(column);
            }, this);
        },

        _reindexColumns: function () {
            _.each(this.scrollableColumns, function (column, index) {
                column.index = index;

                var visibleColumn = this._getVisibleColumn(column);
                if (visibleColumn) {
                    visibleColumn.index = index;
                }
            }, this);
        },

        _adjustCurrentColumnIndex: function() {
            var timeframeColumnsToShow = _.filter(this._getColumnsToShow(), function (column) {
                return !this._isPlaceholderColumn(column);
            }, this);

            if (_.isEmpty(timeframeColumnsToShow) && this.currentTimeframeIndex > 0) {
                this.currentTimeframeIndex--;
            }
        },

        _getDisplayIndexForScrollableColumn: function (scrollableColumn) {
            return scrollableColumn.index - this.currentTimeframeIndex + 1;
        },

        _renderButtons: function () {
            this.cmp.drawThemeToggle();
            this.drawAddNewColumnButton();
            this._afterScroll();
        },

        _isPlaceholderColumn: function (column) {
            return column.xtype === 'cardboardplaceholdercolumn';
        },

        _getFirstPlaceholderColumn: function () {
            return _.find(this.getScrollableColumns(), function (column) {
                return this._isPlaceholderColumn(column);
            }, this);
        },

        _onNewlyAddedColumnReady: function () {
            this.cmp.applyLocalFilters();
        },

        _sizeButtonToColumnHeader: function(button, column){
            var columnHeaderHeight = column.getHeaderTitle().getHeight() - 30;

            button.getEl()
                .setHeight(columnHeaderHeight)
                .setStyle('margin-top', '28px');
        },

        getFirstVisibleScrollableColumn: function () {
            return this.getScrollableColumns()[0];
        },

        getLastVisibleScrollableColumn: function () {
            return _.last(this.getScrollableColumns());
        },

        getScrollableColumns: function () {
            var columns = this.cmp.getColumns();
            return columns ? columns.slice(1) : [];
        }
    });
})();
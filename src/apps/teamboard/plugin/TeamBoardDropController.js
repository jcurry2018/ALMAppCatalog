(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.plugin.TeamBoardDropController', {
        alias: 'plugin.rallyteamboarddropcontroller',
        extend: 'Rally.ui.cardboard.plugin.ColumnDropController',
        requires: ['Rally.data.util.RecordCollection'],

        handleBeforeCardDroppedSave: function (options) {
            Rally.data.util.RecordCollection.modify({
                add: [options.column.getValue()],
                collectionName: options.column.attribute,
                parentRecord: options.record,
                remove: [options.sourceColumn.getValue()],
                saveOptions: {
                    success: function(){
                        this._onDropSaveSuccess(options.column, options.sourceColumn, options.card, options.record, options.type);
                    },
                    failure: function(){
                        this._onDropSaveFailure(options.column, options.sourceColumn, undefined, options.record, options.card, options.sourceIndex, {});
                    },
                    scope: this
                }
            });
        }
    });

})();
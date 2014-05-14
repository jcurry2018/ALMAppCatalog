(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.TeamBoardDropController', {
        alias: 'plugin.rallyteamboarddropcontroller',
        extend: 'Rally.ui.cardboard.plugin.ColumnDropController',

        handleBeforeCardDroppedSave: function (options) {
            options.record.getCollection(options.column.attribute, {
                autoLoad: true,
                limit: Infinity,
                listeners: {
                    load: function(store){
                        store.add(options.column.getValue());
                        store.remove(options.sourceColumn.getValue());
                        store.sync({
                            success: function(){
                                this._onDropSaveSuccess(options.column, options.sourceColumn, options.card, options.record, options.type);
                            },
                            failure: function(){
                                this._onDropSaveFailure(options.column, options.sourceColumn, undefined, options.record, options.card, options.sourceIndex, {});
                            },
                            scope: this
                        });
                    },
                    scope: this
                }
            });
        }
    });

})();
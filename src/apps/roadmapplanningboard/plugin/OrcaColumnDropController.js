(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.plugin.OrcaColumnDropController', {
        extend: 'Rally.ui.cardboard.plugin.ColumnDropController',
        alias: 'plugin.orcacolumndropcontroller',

        config: {
            dragDropEnabled: true
        },

        init: function (column) {
            this.callParent(arguments);
            this.cmp = column;
        },

        mayDrop: function (cards) {
            return this.dragDropEnabled;
        },

        canDragDropCard: function (card) {
            return this.mayDrop() && this.callParent(arguments);
        },

        handleBeforeCardDroppedSave: function (options) {
            var sourceIsBacklog = !options.sourceColumn.planRecord;
            var destIsBacklog = !options.column.planRecord;

            if(sourceIsBacklog && destIsBacklog) {
                return this.callParent(arguments);
            } else if (sourceIsBacklog) {
                return this._moveOutOfBacklog(options);
            } else if (destIsBacklog) {
                return this._moveIntoBacklog(options);
            } else {
                return this._moveFromColumnToColumn(options);
            }
        },

        _moveIntoBacklog: function (options) {
            var planRecord = options.sourceColumn.planRecord;

            planRecord.set('features', _.filter(planRecord.get('features'), function (feature) {
                return feature.id !== '' + options.record.getId();
            }));

            // Remove card from plan column
            planRecord.save({
                requester: options.column,
                scope: this
            });

            // Rank card on backlog column
            if (options.column.fireEvent('beforecarddroppedsave', options.column, options.card)) {
                options.record.save({
                    requester: options.column,
                    callback: function (updatedRecord, operation) {
                        if (operation.success) {
                            return this._onDropSaveSuccess(options.column, options.sourceColumn, options.card, options.record, "move");
                        } else {
                            return this._onDropSaveFailure(options.column, options.sourceColumn, options.record, options.card, options.sourceIndex, response);
                        }
                    },
                    scope: this,
                    params: options.params
                });
            }
        },

        _moveOutOfBacklog: function (options) {
            var planRecord = options.column.planRecord;

            planRecord.set('features', planRecord.get('features').concat({
                id: options.record.getId().toString(),
                ref: options.record.getUri()
            }));

            planRecord.save({
                success: function () {
                    return this._onDropSaveSuccess(options.column, null, options.card, options.record, "move");
                },
                failure: function (response, opts) {
                    return this._onDropSaveFailure(options.column, options.sourceColumn, options.record, options.card, options.sourceIndex, response);
                },
                requester: options.column,
                scope: this,
                params: options.params
            });
        },

        _moveFromColumnToColumn: function (options) {

            var me = this;
            var uuidMapper = Deft.Injector.resolve('uuidMapper');
            var context = this.cmp.context || Rally.environment.getContext();
            var srcPlanRecord = options.sourceColumn.planRecord;
            var destPlanRecord = options.column.planRecord;

            srcPlanRecord.set('features', _.filter(srcPlanRecord.get('features'), function (feature) {
                return feature.id !== '' + options.record.getId();
            }));
            destPlanRecord.get('features').push({
                id: options.record.getId().toString(),
                ref: options.record.getUri()
            });

            uuidMapper.getUuid(context.getWorkspace()).then(function (uuid) {
                Ext.Ajax.request({
                    method: 'POST',
                    withCredentials: true,
                    url: me._constructUrl(srcPlanRecord.get('roadmap'), srcPlanRecord.getId(), destPlanRecord.getId()),
                    jsonData: {
                        id: options.record.getId() + '',
                        ref: options.record.getUri()
                    },
                    success: function () {
                        srcPlanRecord.dirty = false; // Make sure the record is clean
                        return me._onDropSaveSuccess(options.column, options.sourceColumn, options.card, options.record, options.type);
                    },
                    failure: function (response, opts) {
                        return me._onDropSaveFailure(options.column, options.sourceColumn, options.record, options.card, options.sourceIndex, response);
                    },
                    scope: me,
                    params: Ext.apply({ workspace: uuid }, options.params)
                });
            });
        },

        _constructUrl: function (roadmap, sourceId, destinationId) {
            return Ext.create('Ext.XTemplate', Rally.environment.getContext().context.services.planning_service_url + '/roadmap/{roadmap.id}/plan/{sourceId}/features/to/{destinationId}').apply({
                sourceId: sourceId,
                destinationId: destinationId,
                roadmap: roadmap
            });
        }
    });

})();

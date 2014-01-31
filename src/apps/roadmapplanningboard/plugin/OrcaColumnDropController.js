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

            this._removeFeature(planRecord, options.record);

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

            this._addFeature(planRecord, options.record, options.index);

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
            var context = this.cmp.context || Rally.environment.getContext();
            var srcPlanRecord = options.sourceColumn.planRecord;
            var destPlanRecord = options.column.planRecord;

            this._removeFeature(srcPlanRecord, options.record);
            this._addFeature(destPlanRecord, options.record, options.index);


            Ext.Ajax.request({
                method: 'POST',
                withCredentials: true,
                url: this._constructUrl(srcPlanRecord.get('roadmap'), srcPlanRecord.getId(), destPlanRecord.getId()),
                jsonData: {
                    id: options.record.get('_refObjectUUID'),
                    ref: this._getFeatureRef(options.record)
                },
                success: function () {
                    srcPlanRecord.commit();
                    if (srcPlanRecord !== destPlanRecord) {
                        destPlanRecord.commit();
                    }
                    return this._onDropSaveSuccess(options.column, options.sourceColumn, options.card, options.record, options.type);
                },
                failure: function (response, opts) {
                    return this._onDropSaveFailure(options.column, options.sourceColumn, options.record, options.card, options.sourceIndex, response);
                },
                scope: this,
                params: Ext.apply({ workspace: context.getWorkspace()._refObjectUUID}, options.params)
            });
        },

        _removeFeature: function (planRecord, featureRecord) {
            var featureIdToRemove =  featureRecord.get('_refObjectUUID');

            planRecord.set('features', _.filter(planRecord.get('features'), function (feature) {
                return feature.id !== featureIdToRemove;
            }));
        },

        _getFeatureRef: function(featureRecord) {
            var featureId = featureRecord.get('_refObjectUUID');
            return '/' + featureRecord.getRef().reference.type  + '/' + featureId;
        },

        _addFeature: function (planRecord, featureRecord, index) {
            var features = _.clone(planRecord.get('features'));

            var featureId = featureRecord.get('_refObjectUUID');

            features.splice(index, 0, {
                id: featureId,
                ref: this._getFeatureRef(featureRecord)
            });

            planRecord.set('features', features);
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

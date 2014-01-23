(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.roadmapplanningboard.util.RequestCollectionHelper', {
        singleton: true,

        updateRequestIfCollection: function (request, onItemAddedToCollection, onItemRemovedFromCollection) {
            _.each(request.records, function (record) {
                var fields = record.getDirtyCollectionFields();
                if (fields.length) {
                    request = this._processCollectionField(fields, record, request, onItemAddedToCollection, onItemRemovedFromCollection);
                }
            }, this);

            return request;
        },

        _processCollectionField: function (fields, record, request, onItemAddedToCollection, onItemRemovedFromCollection) {
            // make sure this is the only change
            if (record.getDirtyFields().length > 1) {
                Ext.Error.raise('Cannot update other fields on a record if a collection has changed');
            }

            var field = fields[0];
            var fieldName = fields[0].name;

            var oldValue = record.modified[fieldName];
            var newValue = record.get(fieldName);

            if (newValue.length > oldValue.length) {
                // make sure we're only adding 1 relationship
                if (newValue.length - oldValue.length > 1) {
                    Ext.Error.raise('Cannot add more than one relationship at a time');
                }

                onItemAddedToCollection(field, oldValue, newValue, record, request);
            } else if (newValue.length < oldValue.length) {
                // make sure we're only removing 1 relationship
                if (oldValue.length - newValue.length > 1) {
                    Ext.Error.raise('Cannot delete more than one relationship at a time');
                }

                onItemRemovedFromCollection(field, oldValue, newValue, record, request);
            } else {
                Ext.Error.raise('Attempting to update a collection where nothing has changed');
            }

            return request;
        }
    });
}).call(this);
(function () {
    var Ext = window.Ext4 || window.Ext;

    /**
     * @private
     * A {@link Ext.data.writer.Json} subclass that talks to a Rally REST JSON API service
     */
    Ext.define('Rally.apps.roadmapplanningboard.Writer', {
        extend: 'Ext.data.writer.Json',
        alias: 'writer.roadmap',
        requires: ['Rally.apps.roadmapplanningboard.util.RequestCollectionHelper'],
        root: '',

        write: function (request) {
            this.callParent(arguments);

            Rally.apps.roadmapplanningboard.util.RequestCollectionHelper.updateRequestIfCollection(this.callParent(arguments),
                this._onItemAdded, this._onItemRemoved);

            return request;
        },

        _onItemAdded: function (field, oldValue, newValue, record, request) {
            request.url += '/' + field.name;

            var addedId = _.difference(_.pluck(newValue, record.idProperty), _.pluck(oldValue, record.idProperty))[0];
            request.jsonData = _.find(newValue, function (value) {
                return addedId === value.id;
            });
        },

        _onItemRemoved: function (field, oldValue, newValue, record, request) {
            var deletedId = _.difference(_.pluck(oldValue, record.idProperty), _.pluck(newValue, record.idProperty))[0];

            request.url += '/' + field.name + '/' + deletedId;

            // need to change param to urlParams as DELETE will be fired and need the params on the URL thank you Ext
            request.urlParams = request.params;
            delete request.jsonData;
        }
    });
})();

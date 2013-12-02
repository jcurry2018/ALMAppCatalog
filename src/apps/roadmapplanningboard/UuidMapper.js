(function () {
    var Ext = window.Ext4 || window.Ext;

    var UUID_FORMAT = /[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/;

    /**
     * @private
     * This class allows mapping from ObjectIDs to UUIDs for any WSAPI domain object
     */
    Ext.define('Rally.apps.roadmapplanningboard.UuidMapper', {
        requires: [
            'Rally.util.Ref'
        ],

        constructor: function () {
            this.mappings = {};
        },

        /**
         * @param {Object|Object[]} domainObject The domain object to extract a uuid from. Use record.data for this parameter if this is a model
         * @returns {Deft.promise.Promise}
         */
        getUuid: function (domainObjects) {
            var me = this;

            if (Ext.isArray(domainObjects)) {
                return Deft.promise.Promise.all(_.map(domainObjects, function (domainObject) { return me._getUuid(domainObject); }));
            } else {
                return this._getUuid(domainObjects);
            }

        },

        /**
         * @private
         * @param {Object} domainObject The domain object to extract a uuid from. Use record.data for this parameter if this is a model
         * @returns {Deft.promise.Promise}
         */
        _getUuid: function (domainObject) {
            var me = this;
            var deferred = Ext.create('Deft.promise.Deferred');
            var ObjectID = domainObject.ObjectID.toString();

            if (this.mappings[ObjectID]) {
                deferred.resolve(this.mappings[ObjectID]);
            } else {

                // If the ObjectID is already a UUID, just resolve with the value
                if (ObjectID.match(UUID_FORMAT)) {
                    deferred.resolve(ObjectID);
                } else {
                    this._getUuidFromWsapi(domainObject).then(function (uuid) {
                        me.mappings[ObjectID] = uuid;
                        deferred.resolve(uuid);
                    }).otherwise(function (error) {
                        deferred.reject(error);
                    });
                }
            }

            return deferred.promise;
        },

        /**
         * @private
         */
        _getUuidFromWsapi: function (domainObject) {
            var ref = Ext.create('Rally.util.Ref', domainObject._ref);
            var deferred = Ext.create('Deft.promise.Deferred');
            ref.setVersion('v3.0');

            Ext.Ajax.request({
                url: ref.getUri(),
                params: { fetch: 'ObjectID' },
                defaultHeaders: { Accept: 'text/javascript' },
                method: 'GET',
                success: function(response) {
                    var result = Ext.decode(response.responseText);
                    var type = _.keys(result)[0];
                    deferred.resolve(result[type].ObjectID);
                },
                failure: function(error) {
                    deferred.reject(error);
                },
                scope: this,
                requester: this
            });

            return deferred.promise;
        }

    });

})();

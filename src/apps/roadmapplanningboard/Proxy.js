(function() {

    var Ext = window.Ext4 || window.Ext;

    /**
     * @private
     * Proxy to talk to Rally REST JSON API services
     */
    Ext.define('Rally.apps.roadmapplanningboard.Proxy', {
        extend: 'Ext.data.proxy.Rest',
        requires: [
            'Rally.apps.roadmapplanningboard.Writer',
            'Rally.apps.roadmapplanningboard.Reader',
            'Rally.ui.notify.Notifier',
            'Rally.apps.roadmapplanningboard.util.RequestCollectionHelper'
        ],
        alias: 'proxy.roadmap',

        reader: {
            type: 'roadmap'
        },

        writer: {
            type: 'roadmap',
            writeAllFields: false
        },

        doRequest: function (operation, callback, scope) {
            operation = this._decorateOperation(operation);
            return this.callParent(arguments);
        },

        /**
         * Decorate each request operation with params for workspace and project UUIDs.
         * @param {Object} operation
         * @returns {Object} operation
         */
        _decorateOperation: function(operation) {
            var context = operation.context || Rally.environment.getContext();

            operation.noQueryScoping = true;
            operation.params = operation.params || {};
            operation.params.workspace = context.getWorkspace()._refObjectUUID || '';
            operation.params.project = context.getProject()._refObjectUUID || '';

            return operation;
        },

        /**
         * This method will build the url running it through an {Ext.XTemplate} with the operation params
         * @param {Object} request
         * @returns {String} url
         */
        buildUrl: function (request) {
            var recordData = (request.records && request.records[0].data) || {};
            var data = _.merge({}, request.operation.params, recordData);
            return new Ext.XTemplate(this.getUrl(request)).apply(data);
        },

        buildRequest: function(operation) {
            var request = Rally.apps.roadmapplanningboard.util.RequestCollectionHelper.updateRequestIfCollection(this.callParent(arguments),
                this._onItemAdded, this._onItemRemoved);
            request.withCredentials = true;

            return request;
        },

        _onItemAdded: function (field, oldValue, newValue, record, request) {
            request.action = 'create';
        },

        _onItemRemoved: function (field, oldValue, newValue, record, request) {
            request.action = 'destroy';
        }
    });

})();

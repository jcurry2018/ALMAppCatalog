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
            'Rally.ui.notify.Notifier'
        ],
        alias: 'proxy.roadmap',

        reader: {
            type: 'json',
            root: 'results'
        },

        writer: {
            type: 'roadmap',
            writeAllFields: false
        },

        doRequest: function (operation, callback, scope) {
            operation.noQueryScoping = true;
            operation = this._decorateWithWorkspaceAndProject(operation);
            return this.callParent(arguments);
        },

        /**
         * Decorate each request operation with params for workspace and project UUIDs.
         * @param {Object} operation
         * @returns {Object} operation
         */
        _decorateWithWorkspaceAndProject: function(operation) {
            var context = operation.context || Rally.environment.getContext();

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
            var request = this.callParent(arguments);
            request.withCredentials = true;
            return request;
        }
    });

})();

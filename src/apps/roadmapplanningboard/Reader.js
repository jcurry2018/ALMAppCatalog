(function () {
    var Ext = window.Ext4 || window.Ext;

    /**
     * @private
     * A {@link Ext.data.reader.Json} subclass that reads a Rally REST JSON API response
     */
    Ext.define('Rally.apps.roadmapplanningboard.Reader', {
        extend: 'Ext.data.reader.Json',
        alias: 'reader.roadmap',

        root: 'results',

        /**
         * The RPM services don't wrap all requests in arrays. For example a create returns the resource data and not
         * an array wrapping that data. Ext expects arrays at the root for creates. This method simply wraps the data
         * in the root inside an array if appropriate. Yay Ext.
         * @param data
         * @returns {Object} The data from
         */
        readRecords: function(data) {
            data = data[this.root] ? data : {results: [data]};

            return this.callParent([data]);
        }
    });
})();

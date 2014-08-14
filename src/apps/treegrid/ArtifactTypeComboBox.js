(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.treegrid.ArtifactTypeComboBox', {
        extend: 'Rally.ui.combobox.ComboBox',
        alias: 'widget.rallyartifactypecombobox',

        constructor: function(config) {
            config = config || {};


            this.callParent([_.assign(this._getConfig(), config)]);
        },

        _getConfig: function() {
            return {
                storeConfig: {
                    model: 'TypeDefinition',
                    filters: [this._getArtifactTypeFilter()],
                    sorters: [{property: 'DisplayName'}],
                    fetch: ['DisplayName', 'ElementName', 'Name', 'TypePath'],
                    autoLoad: false,
                    remoteSort: false,
                    remoteFilter: true
                },
                displayField: 'DisplayName',
                valueField: 'TypePath'
            };
        },

        _getArtifactTypeFilter: function() {
            var artifactFilter = Rally.data.wsapi.Filter.or([
                    {
                        property: 'TypePath',
                        value: 'hierarchicalrequirement',
                        operator: '='
                    },
                    {
                        property: 'TypePath',
                        value: 'defect',
                        operator: '='
                    },
                    {
                        property: 'TypePath',
                        value: 'defectsuite',
                        operator: '='
                    },
                    {
                        property: 'TypePath',
                        value: 'testset',
                        operator: '='
                    },
                    {
                        property: 'TypePath',
                        value: 'testcase',
                        operator: '='
                    },
                    {
                        property: 'TypePath',
                        value: 'task',
                        operator: '='
                    }
                ]),
                portfolioItemFilter = Rally.data.wsapi.Filter.and([
                    {
                        property: 'Parent.TypePath',
                        value: 'portfolioitem',
                        operator: '='
                    },
                    {
                        property: 'Ordinal',
                        value: '-1',
                        operator: '>'
                    }
                ]);

            return artifactFilter.or(portfolioItemFilter);
        }
    });
})();
(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.common.TimeBoxesGridBoardApp', {
        extend: 'Rally.app.GridBoardApp',
        requires: ['Rally.ui.DateField'],

        enableXmlExport: true,

        getAddNewConfig: function () {
            return Ext.apply(this.callParent(arguments), {
                additionalFields: [
                    {
                        xtype: 'rallydatefield',
                        allowBlank: false,
                        emptyText: this.startDateEmptyText,
                        name: this.startDateFieldName,
                        paramName: 'startDate'
                    }, {
                        xtype: 'rallydatefield',
                        allowBlank: false,
                        emptyText: this.endDateEmptyText,
                        name: this.endDateFieldName,
                        paramName: 'endDate'
                    }
                ],
                ignoredRequiredFields: ['GrossEstimateConversionRatio', 'Name', 'Project', 'State', this.startDateFieldName, this.endDateFieldName],
                listeners: {
                    beforecreate: this._onBeforeCreate
                },
                minWidth: 800,
                openEditorAfterAddFailure: false,
                showAddWithDetails: true,
                showRank: false
            });
        },

        getFilterControlConfig: function () {
            return {
                blackListFields: ['GrossEstimateConversionRatio', 'Theme']
            };
        },

        getGridConfig: function () {
            return _.merge(this.callParent(arguments), {
                enableSummaryRow: false,
                rowActionColumnConfig: {
                    menuOptions: {
                        showInlineAdd: false
                    }
                }
            });
        },

        getGridStoreConfig: function() {
            return _.merge(this.callParent(arguments), {
                sorters: [ {property: this.startDateFieldName, direction: 'DESC'} ]
            });
        },

        _onBeforeCreate: function(addNew, record) {
            record.set('State', 'Planning');
        }
    });
})();
(function() {
    var Ext = window.Ext4 || window.Ext;

    /**
     * Allows configuring of rows for the cardboard
     *
     *
     *      @example
     *      Ext.create('Ext.Container', {
         *          items: [{
         *              xtype: 'rowsettingsfield',
         *              value: {
         *                  show: true,
         *                  field: 'c_ClassofService'
         *              }
         *          }],
         *          renderTo: Ext.getBody().dom
         *      });
     *
     */
    Ext.define('Rally.apps.common.RowSettingsField', {
        alias: 'widget.rowsettingsfield',
        extend: 'Ext.form.FieldContainer',
        requires: [
            'Rally.ui.CheckboxField',
            'Rally.ui.combobox.ComboBox',
            'Rally.ui.plugin.FieldValidationUi',
            'Rally.data.ModelFactory',
            'Rally.domain.WsapiModelBuilder'
        ],

        mixins: {
            field: 'Ext.form.field.Field'
        },

        layout: 'hbox',

        cls: 'row-settings',

        config: {
            /**
             * @cfg {Object}
             *
             * The row settings value for this field
             */
            value: undefined
        },

        initComponent: function() {
            this.callParent(arguments);

            this.mixins.field.initField.call(this);

            this.add([
                {
                    xtype: 'rallycheckboxfield',
                    name: 'showRows',
                    boxLabel: '',
                    submitValue: false,
                    value: this.getValue().showRows,
                    listeners: {
                        change: function(checkbox, checked) {
                            this.down('rallycombobox').setDisabled(!checked);
                        },
                        scope: this
                    }
                },
                {
                    xtype: 'rallycombobox',
                    plugins: ['rallyfieldvalidationui'],
                    name: 'rowsField',
                    margin: '0 5px',
                    displayField: 'name',
                    valueField: 'value',
                    disabled: this.getValue().showRows !== 'true',
                    editable: false,
                    submitValue: false,
                    storeType: 'Ext.data.Store',
                    storeConfig: {
                        remoteFilter: false,
                        fields: ['name', 'value'],
                        data: []
                    }
                }
            ]);

            Rally.data.ModelFactory.getModels({
                types: ['userstory', 'defect'],
                context: this.context,
                success: this._onModelsRetrieved,
                scope: this
            });
        },

        _onModelsRetrieved: function (models) {
            var explicitFields = [
                    {'name': 'Blocked', 'value': 'Blocked'},
                    {'name': 'Owner', 'value': 'Owner'},
                    {'name': 'Sizing', 'value': 'PlanEstimate'},
                    {'name': 'Expedite', value: 'Expedite'}
                    //TODO: type?
                ],
                fields = explicitFields.concat(this._getRowableFields(_.values(models)));

            var combobox = this.down('rallycombobox');
            combobox.getStore().loadData(_.sortBy(fields, 'name'));
            combobox.setValue(this.getValue().rowsField);
            this.fireEvent('ready', this);
        },

        _getRowableFields: function (models) {
            var artifactModel = Rally.domain.WsapiModelBuilder.buildCompositeArtifact(models, this.context),
                allFields = artifactModel.getFields(),
                rowableFields = _.filter(allFields, function (field) {
                    var attr = field.attributeDefinition;
                    return !field.hidden &&
                        attr &&
                        attr.Custom &&
                        attr.Constrained &&
                        artifactModel.getModelsForField(field).length === models.length;
                });

            return _.map(rowableFields, function(field) {
                return {
                    name: field.displayName,
                    value: field.name
                };
            });
        },

        /**
         * When a form asks for the data this field represents,
         * give it the name of this field and the ref of the selected project (or an empty string).
         * Used when persisting the value of this field.
         * @return {Object}
         */
        getSubmitData: function() {
            var data = {};
            var showRows = this.down('rallycheckboxfield');
            data[showRows.name] = showRows.getValue();
            if (showRows.getValue()) {
                var rowsField = this.down('rallycombobox');
                data[rowsField.name] = rowsField.getValue();
            }
            return data;
        }
    });
})();



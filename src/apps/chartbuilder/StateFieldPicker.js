(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define("Rally.apps.chartbuilder.StateFieldPicker", {
        // extend: 'Ext.form.FieldContainer',
        extend: 'Ext.form.FieldSet',
        alias: 'widget.rallychartbuildersettingsstatefieldpicker',

        requires: [
            'Rally.ui.combobox.FieldComboBox',
            'Rally.ui.combobox.FieldValueComboBox'
        ],

        mixins: {
            field: 'Ext.form.field.Field'
        },

        // extjs properties
        flex: 1,
        border: false,
        width: 480,
        layout: 'vbox',
        defaultType: 'textfield',
        items: [],
        stateFieldName: null,
        stateFieldValues: null,

        initComponent: function() {
            this.callParent(arguments);
            this.mixins.field.initField.call(this);

            this._addStateFieldPicker();

            this.on('statefieldnameselected', this._onStateFieldNameSelected);
            this.on('statefieldnameready', this._onStateFieldNameReady);
            this.on('statefieldvaluesready', this._onStateFieldValuesReady);
            this.on('statefieldvalueschanged', this._onStateFieldValuesChanged);
        },

        /**
         * Event handling
         */
        _onStateFieldNameSelected: function(fieldDefinition) {
            // This happens on field change
            this._refreshStateValuesPicker(fieldDefinition.name);
        },

        _onStateFieldNameReady: function() {
            // This happens on initial settings panel load
            this._updateStateFieldComboboxValue();
            this._refreshStateValuesPicker(this.stateFieldName);
        },

        _onStateFieldValuesReady: function(combo) {
            // This happens on field values combo box ready
            if (_.isString(this.stateFieldValues)) {
                var values = [];
                values = this.stateFieldValues.split(',');
                combo.setValue(values);
            }

            this._publishComponentReady();
        },

        _onStateFieldValuesChanged: function(combo, records) {
            this._sortDisplayedStatesByStore(combo, records);
        },

        _sortDisplayedStatesByStore: function(combo, records) {
            var i, j;
            var values=[];
            if(records.length > 0) {
              for (i=0;i<records[0].store.data.items.length;i++) {
                  for(j=0;j<records.length;j++) {
                     if(records[j].data.StringValue === records[0].store.data.items[i].data.StringValue) {
                         values.push(records[j].data.StringValue);
                     }
                  }
              }
            }
            combo.setValue(values);
            this.stateFieldValues = values.join(',');
        },

        _publishComponentReady: function() {
            if (Rally.BrowserTest) {
                Rally.BrowserTest.publishComponentReady(this);
            }
        },

        _updateStateFieldComboboxValue: function() {
            if (this.stateFieldName) {
                var combo = this.down('rallyfieldcombobox');
                combo.setValue(this.stateFieldName);
            }
        },

        _refreshStateValuesPicker: function(fieldName) {
            // if values picker already exists, destroy it
            var old = this.down('rallyfieldvaluecombobox');
            if (old) {
                this.remove(old);
            }
            this._addStateValuesPicker(fieldName);
        },

        _addStateFieldPicker: function() {
            var self = this;
            this.add({
                name: 'stateFieldName',
                xtype: 'rallyfieldcombobox',
                itemId: 'stateFieldName',
                submitValue : false,
                value: self.stateFieldName,
                model: Ext.identityFn('UserStory'),
                margin: '10px 0 0 0',
                width: 240,
                fieldLabel: 'Field',
                listeners: {
                    select: function(combo) {
                        this.fireEvent('statefieldnameselected', combo.getRecord().get('fieldDefinition'));
                        self.stateFieldName = combo.getRecord().get('fieldDefinition').name;
                    },
                    ready: function(combo) {
                        combo.store.filter({filterFn: function(record) {
                            var attr = record.get('fieldDefinition').attributeDefinition;
                            return attr && !attr.ReadOnly && attr.Constrained && attr.AttributeType !== 'OBJECT' && attr.AttributeType !== 'COLLECTION';
                        }});

                        if (combo.getRecord()) {
                            this.fireEvent('statefieldnameready');
                        } else {
                            self.fireEvent('ready', self);
                        }
                    }
                },
                bubbleEvents: ['statefieldnameselected', 'statefieldnameready']
            });
        },

        _addStateValuesPicker: function(fieldName) {
            this.add({
                xtype: 'rallyfieldvaluecombobox',
                model: Ext.identityFn('UserStory'),
                field: fieldName,
                submitValue : false,
                itemId: 'stateFieldValues',
                name: 'stateFieldValues',
                valueField: "StringValue",
                displayField: "StringValue",
                multiSelect: true,
                readyEvent: 'ready',
                fieldLabel: 'Show states',
                margin: '10px 0 0 0',
                width: 400,
                forceSelection: true,
                allowBlank: false,
                listeners: {
                    ready: function(combo) {
                        this.fireEvent('statefieldvaluesready', this);
                    },
                    select: function(combo, records) {
                        this.fireEvent('statefieldvalueschanged', combo, records);
                    }
                },
                listConfig: {
                    itemTpl: Ext.create('Ext.XTemplate',
                        '<div class="statefieldvalue-boundlist-item"><img src="' + Ext.BLANK_IMAGE_URL + '" class="stateFieldValue"/> &nbsp;{StringValue}</div>'),
                    listeners:{
                        afterrender: function(){
                            this.selectedItemCls = Ext.baseCSSPrefix + 'boundlist-selected statefieldvalue-boundlist-selected';
                        }
                    }
                },
                bubbleEvents: ['statefieldvaluesready', 'statefieldvalueschanged']
            });
        },

        setValue: function(value) {
            try {
                var json = JSON.parse(value);
                if (Ext.isObject(json)) {
                    this.stateFieldName = json.name || null;
                    this.stateFieldValues = json.values || null;
                }
            } catch (e) {
                console.error("error:", e);
            }
        },

        getValue: function() {
            return JSON.stringify({ name: this.stateFieldName, values: this.stateFieldValues });
        }
    });
}());

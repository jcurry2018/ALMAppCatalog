(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.TeamBoardSettings', {
        requires: [
            'Rally.ui.combobox.ComboBox',
            'Rally.ui.picker.FieldPicker',
            'Rally.ui.picker.MultiObjectPicker'
        ],
        singleton: true,

        getFields: function(userModel){
            return [this._getTeamsPickerConfig(), this._getFieldPickerConfig(), this._getGroupByPickerConfig(userModel)];
        },

        _getTeamsPickerConfig: function(){
            return {
                xtype: 'rallymultiobjectpicker',
                alwaysExpanded: true,
                availableTextLabel: 'Available Teams',
                fieldLabel: 'Teams',
                pickerCfg: {
                    style: {
                        border: '1px solid #DDD',
                        'border-top': 'none'
                    },
                    height: 248,
                    shadow: false
                },
                margin: '10px 0 265px 0',
                maintainScrollPosition: true,
                modelType: 'Project',
                name: 'teamOids',
                pickerAlign: 'tl-bl',
                selectedTextLabel: 'Selected Teams',
                selectionKey: 'ObjectID',
                storeLoadOptions: {
                    params: {
                        order: 'Name ASC'
                    }
                },
                width: 300
            };
        },

        _getFieldPickerConfig: function(){
            return {
                xtype: 'rallyfieldpicker',
                fieldLabel: 'Card Fields',
                name: 'cardFields',
                modelTypes: ['User']
            };
        },

        _getGroupByPickerConfig: function(userModel) {
            var groupByFields = _.filter(userModel.getFields(), function(field){
                return field.getType() === 'rating' || field.hasAllowedValues();
            });

            return {
                xtype: 'rallycombobox',
                allowNoEntry: true,
                editable: false,
                fieldLabel: 'Group By',
                name: 'groupBy',
                queryMode: 'local',
                store: _.map(_.sortBy(groupByFields, 'displayName'), function(field){
                    return [field.name, field.displayName];
                })
            };
        }
    });

})();
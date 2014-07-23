(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.plugin.TeamBoardIterationAwarePlugin', {
        extend: 'Ext.AbstractPlugin',

        init: function(cmp) {
            this.callParent(arguments);

            this.cmp = cmp;
            this.cmp.on('iterationcomboready', this.onIterationComboReady, this, {single: true});
        },

        findIterationRecord: function(ref, combo) {
            return ref && combo.findRecordByValue(ref);
        },

        onIterationComboReady: function(cmp, combo){
            combo.on('change', this.onIterationComboChange, this);
            this.showData(this.findIterationRecord(combo.getValue(), combo));
        },

        onIterationComboChange: function(combo, newValue){
            this.showData(this.findIterationRecord(newValue, combo));
        },

        showData: Ext.emptyFn
    });
})();
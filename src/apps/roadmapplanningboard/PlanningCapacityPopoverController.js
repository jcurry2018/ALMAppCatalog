(function () {
    var Ext = window.Ext4 || window.Ext;
    Ext.define('Rally.apps.roadmapplanningboard.PlanningCapacityPopoverController', {
        extend: 'Deft.mvc.ViewController',
        config: {
            model: null
        },
        control: {
            view: {
                blur: function () {
                    this.persistIfChangedAndValid();
                },
                validitychange: function () {
                    this.onValidityChange();
                }
            }
        },

        clientMetrics: {
            descriptionProperty: 'getClickAction',
            method: 'onBeforeDestroy'
        },

        init: function () {
            this.callParent(arguments);
            if (!this.model) {
                throw "Model is required";
            }
            var lowCapacity = this.model.get('lowCapacity') || 0;
            this.getView().getLowCapacityField().setValue(lowCapacity).resetOriginalValue();
            var highCapacity = this.model.get('highCapacity') || 0;
            this.getView().getHighCapacityField().setValue(highCapacity).resetOriginalValue();
        },

        validateRange: function () {
            var lowValue = this.getView().getLowCapacityField().getValue();
            var highValue = this.getView().getHighCapacityField().getValue();

            return highValue >= lowValue || "Low estimate should not exceed the high estimate";
        },

        persistIfChangedAndValid: function () {
            var lowField = this.getView().getLowCapacityField();
            var highField = this.getView().getHighCapacityField();

            if (lowField.isDirty() || highField.isDirty()) {
                var lowValue = lowField.getValue() || 0;
                var highValue = highField.getValue() || 0;

                if (lowField.validate() && highField.validate()) {
                    lowField.resetOriginalValue();
                    highField.resetOriginalValue();
                    this.persistIfStoreAvailable(lowValue, highValue);
                }
            }
        },

        persistIfStoreAvailable: function (lowValue, highValue) {
            var requester;
            this.model.beginEdit();
            this.model.set('lowCapacity', lowValue);
            this.model.set('highCapacity', highValue);
            this.model.endEdit();

            if (this.view && this.view.owner && this.view.owner.ownerCardboard) {
                requester = this.view.owner.ownerCardboard;
            }
            return this.model.save({
                requester: requester
            });
        },

        onValidityChange: function () {
            var lowField = this.getView().getLowCapacityField();
            var highField = this.getView().getHighCapacityField();

            lowField.isValid();
            highField.isValid();
        }
    });

}).call(this);

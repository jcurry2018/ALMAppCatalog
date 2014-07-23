(function() {
    var Ext = window.Ext4 || window.Ext;

    /**
     * @private
     * Allows displaying the stats banner settings
     *
     *
     *      @example
     *      Ext.create('Ext.Container', {
         *          items: [{
         *              xtype: 'rallystatsbannersettingsfield',
         *              value: {
         *                  showStatsBanner: true
         *              }
         *          }],
         *          renderTo: Ext.getBody().dom
         *      });
     *
     */
    Ext.define('Rally.apps.iterationtrackingboard.StatsBannerField', {
        extend: 'Ext.form.FieldContainer',
        requires: [
            'Rally.ui.CheckboxField'
        ],
        alias: 'widget.rallystatsbannersettingsfield',

        mixins: {
            field: 'Ext.form.field.Field'
        },

        layout: 'hbox',

        cls: 'stats-banner-settings',

        config: {
            /**
             * @cfg {Object}
             *
             * The column settings value for this field
             */
            value: undefined
        },

        initComponent: function() {
            this.callParent(arguments);

            this.mixins.field.initField.call(this);

            this.add([
                {
                    xtype: 'rallycheckboxfield',
                    name: 'showStatsBanner',
                    boxLabel: 'Show the Iteration Progress Banner',
                    submitValue: false,
                    margin: '0 0 0 80',
                    value: this.getValue().showStatsBanner
                }
            ]);
        },

        /**
         * When a form asks for the data this field represents,
         * give it the name of this field and the ref of the selected project (or an empty string).
         * Used when persisting the value of this field.
         * @return {Object}
         */
        getSubmitData: function() {
            var data = {};
            var showStatsBannerField = this.down('rallycheckboxfield');
            data[showStatsBannerField.name] = showStatsBannerField.getValue();
            return data;
        }
    });
})();



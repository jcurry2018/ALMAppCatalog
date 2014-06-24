(function(){

    var Ext = window.Ext4 || window.Ext;

    /**
    * shows print dialog for Iteration Progress App
    */
    Ext.define('Rally.apps.iterationtrackingboard.PrintDialog', {
        extend: 'Rally.ui.dialog.Dialog',
        alias:'widget.iterationprogessappprintdialog',
        requires: [
            'Rally.ui.Button'
        ],
        config: {
            autoShow: true,
            draggable: true,
            disableScroll: true,
            width: 520,
            height: 300,
            closable: true,
            title: 'Print'
        },
        layout: {
            type: 'vbox',
            align: 'left'
        },
        cls: 'iteration-progress-dialog print-dialog',
        items: [
            {
                xtype: 'container',
                html: 'What would you like to print?',
                cls: 'dialog-title'
            },
            {
                xtype: 'radiogroup',
                vertical: true,
                columns: 1,
                height: 70,
                items: [
                    {
                        boxLabel: 'Summary list of work items',
                        name: 'reportType',
                        inputValue: '1',
                        checked: true
                    },
                    {
                        boxLabel: 'Summary list of work items with children',
                        name: 'reportType',
                        inputValue: '2'
                    }
                ]
            }
        ],
        constructor: function(config) {
            this.initConfig(config || {});
            this.callParent(arguments);
        },

        initComponent: function() {
            var warningTextClasses = this.showWarning ? 'print-warning' : 'print-warning hidden';
            this.items.push({
                xtype: 'container',
                html: '<div class="icon-warning alert"></div></span> Iterations with more than 400 items may cause problems when printing.',
                cls: warningTextClasses,
                itemId: 'tooManyItems'
            });

            this.dockedItems = [{
                xtype: 'toolbar',
                dock: 'bottom',
                layout: {
                    type: 'hbox',
                    pack: 'center'
                },
                ui: 'footer',
                itemId: 'footer',
                defaults: {
                    xtype: 'rallybutton',
                    padding: '4 12',
                    scope: this
                },
                items: [
                    {
                        text: 'Print',
                        cls: 'primary medium',
                        handler: this._handlePrintClick
                    },
                    {
                        text: 'Cancel',
                        cls: 'secondary medium',
                        handler: this._handleCancelClick
                    }
                ]
            }];
            this.callParent(arguments);
        },

        _handlePrintClick: function() {
            //todo: add code to handle the print
        },

        _handleCancelClick: function() {
            this.destroy();
        }
    });
})();

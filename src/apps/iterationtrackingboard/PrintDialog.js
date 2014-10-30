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
                id: 'whattoprint',
                vertical: true,
                columns: 1,
                height: 70,
                width: 470,
                items: [
                    {
                        boxLabel: 'Summary list of work items',
                        name: 'reportType',
                        inputValue: 'summary',
                        checked: true
                    },
                    {
                        boxLabel: 'Summary list of work items with children',
                        id: 'printDialogReportTypeIncludeChildren',
                        name: 'reportType',
                        inputValue: 'includechildren'
                    }
                ]
            }
        ],
        constructor: function(config) {
            this.initConfig(config || {});
            this.timeboxScope = this.config.timeboxScope;

            this.nodesToExpand = [];
            this.allRecords = [];

            this.callParent(arguments);
        },

        initComponent: function() {
            var warningTextClasses = this.showWarning ? 'print-warning' : 'print-warning rly-hidden';
            this.items.push({
                xtype: 'container',
                html: '<div class="icon-warning alert"></div> Print is limited to 200 work items.',
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
            var treeStoreBuilder = Ext.create('Rally.data.wsapi.TreeStoreBuilder');
            var storeConfig = this._buildStoreConfig();
            treeStoreBuilder.build(storeConfig).then({
                success: function(store) {
                    // parent types must be overridden after the store is built because the builder automatically overrides the config
                    store.parentTypes = this.grid.getStore().parentTypes;
                    store.load();
                },
                scope: this
            });
        },

        _handleCancelClick: function(target, e) {
            this.destroy();
        },

        _buildStoreConfig: function() {
            var includeChildren = Ext.getCmp('whattoprint').getChecked()[0].inputValue === 'includechildren';
            var gridStore = this.grid.getStore();
            var fetch = gridStore.fetch;
            var filters = gridStore.filters ? gridStore.filters.items : [];
            var sorters = gridStore.getSorters();

            return {
                models: ['User Story', 'Defect', 'Defect Suite', 'Test Set'],
                autoLoad: false,
                pageSize: 200,
                remoteSort: true,
                root: {expanded: includeChildren},
                enableHierarchy: includeChildren,
                childPageSizeEnabled: false,
                fetch: fetch,
                filters: filters,
                sorters: sorters,
                listeners: {
                    load: this._onStoreLoad,
                    scope: this
                }
            };
        },

        _onStoreLoad: function(treeStore, node, records, success, eOpts) {
            if (_.isEmpty(this.allRecords)) {
                this.allRecords = records;
            }

            if (treeStore.enableHierarchy) {
                this.nodesToExpand = _.without(this.nodesToExpand, node.getId());

                _(records).filter(function(record) {
                    return !record.isLeaf();
                }).forEach(function(record) {
                    this.nodesToExpand.push(record.getId());
                    record.expand(true);
                }, this);
            }

            if (_.isEmpty(this.nodesToExpand)) {
                this._onDataReady();
            }
        },

        _onDataReady: function() {
            var timeboxScopeRecord = this.timeboxScope.getRecord();
            var iterationName = timeboxScopeRecord ? timeboxScopeRecord.get('Name') : 'Unscheduled';
            var treeGridPrinter = Ext.create('Rally.ui.grid.TreeGridPrinter', {
                records: this.allRecords,
                grid: this.grid,
                iterationName: iterationName
            });
            var win = Rally.getWindow();

            if(win.printWindow) {
                win.printWindow.close();
            }

            win.printWindow = win.open(Rally.environment.getServer().getContextUrl() + '/print/printContainer.html', 'printWindow', 'height=600,width=1000,toolbar=no,menubar=no,scrollbars=yes');
            if (!win.printWindow) {
                alert('It looks like you have a popup blocker installed. Please turn this off to see the print window.');
                return;
            }
            treeGridPrinter.print(win.printWindow);
            win.printWindow.focus();

            this.destroy();
        }
    });
})();

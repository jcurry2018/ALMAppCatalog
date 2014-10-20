(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.common.PortfolioItemsGridBoardApp', {
        extend: 'Rally.app.App',
        requires: [
            'Rally.ui.gridboard.GridBoard',
            'Rally.ui.gridboard.plugin.GridBoardCustomFilterControl',
            'Rally.ui.gridboard.plugin.GridBoardFieldPicker',
            'Rally.ui.gridboard.plugin.GridBoardAddNew',
            'Rally.ui.combobox.PortfolioItemTypeComboBox'
        ],

        launch: function () {
            this._createPITypePicker().then({
                success: function (currentType) {
                    this.currentType = currentType;
                    this.loadGridBoard();
                },
                scope: this
            });
        },

        loadGridBoard: function () {
            // Override in child classes
        },

        addGridBoard: function (options) {
            this.gridboard = Ext.create('Rally.ui.gridboard.GridBoard', this.getGridBoardConfig(options));

            this.add(this.gridboard);
            this.addHeader();
        },

        addHeader: function () {
            var header = this.gridboard.getHeader();

            if (header) {
                header.getRight().add(this.getHeaderControls());
            }
        },

        getHeaderControls: function () {
            return [this.piTypePicker];
        },

        getGridBoardConfig: function (options) {
            var currentTypePath = this.currentType.get('TypePath');

            return {
                itemId: 'gridboard',
                stateId: 'portfolio-' + this.stateName + '-gridboard',
                toggleState: this.toggleState,
                modelNames: [currentTypePath],
                context: this.getContext(),
                addNewPluginConfig: {
                    style: {
                        'float': 'left'
                    }
                },
                plugins: _.union([
                    {
                        ptype: 'rallygridboardaddnew',
                        reduceLayouts: this.getContext().isFeatureEnabled('ADD_SPEED_HOLES_TO_TREE_GRID_APPS')
                    },
                    {
                        ptype: 'rallygridboardcustomfiltercontrol',
                        filterChildren: false,
                        filterControlConfig: _.merge({
                            blackListFields: ['PortfolioItemType', 'State'],
                            whiteListFields: [this.milestonesAreEnabled() ? 'Milestones' : ''],
                            modelNames: [currentTypePath],
                            stateful: true,
                            stateId: this.getContext().getScopedStateId('portfolio-' + this.stateName + '-custom-filter-button')
                        }, this.getFilterControlConfig()),
                        showOwnerFilter: true,
                        ownerFilterControlConfig: {
                            stateful: true,
                            stateId: this.getContext().getScopedStateId('portfolio-' + this.stateName + '-owner-filter')
                        }
                    },
                    _.merge({
                        ptype: 'rallygridboardfieldpicker',
                        headerPosition: 'left'
                    }, this.getFieldPickerConfig())
                ], this.getPlugins()),
                cardBoardConfig: this.getCardBoardConfig(options),
                gridConfig: this.getGridConfig(options),
                height: this.getHeight()
            };
        },

        getPlugins: function () {
            return [];
        },

        getFilterControlConfig: function () {
            return {};
        },

        getFieldPickerConfig: function () {
            return {};
        },

        getCardBoardConfig: function () {
            return {};
        },

        getGridConfig: function () {
            return {};
        },

        milestonesAreEnabled: function () {
            var context = this.getContext() ? this.getContext() : Rally.environment.getContext();
            return context.isFeatureEnabled('S70874_SHOW_MILESTONES_PAGE');
        },

        setHeight: function(height) {
            this.callParent(arguments);
            if(this.gridboard) {
                this.gridboard.setHeight(height);
            }
        },

        _createPITypePicker: function () {
            if (this.piTypePicker) {
                this.piTypePicker.destroy();
            }

            var deferred = new Deft.Deferred();

            this.piTypePicker = Ext.create('Rally.ui.combobox.PortfolioItemTypeComboBox', {
                preferenceName: 'portfolioitems' + this.stateName + '-typepicker',
                value: this.getSetting('type'),
                context: this.getContext(),
                listeners: {
                    change: this._onTypeChange,
                    ready: {
                        fn: function (picker) {
                            deferred.resolve(picker.getSelectedType());
                        },
                        single: true
                    },
                    scope: this
                }
            });

            return deferred.promise;
        },

        _onTypeChange: function (picker) {
            var newType = picker.getSelectedType();

            if (this._pickerTypeChanged(picker)) {
                this.currentType = newType;
                this.gridboard.fireEvent('modeltypeschange', this.gridboard, [newType]);
            }
        },

        _pickerTypeChanged: function(picker){
            var newType = picker.getSelectedType();
            return newType && this.currentType && newType.get('_ref') !== this.currentType.get('_ref');
        }
    });
})();
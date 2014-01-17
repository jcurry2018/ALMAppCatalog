(function () {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.charts.iterationburndownminimal.IterationBurnDownMinimalViewToggle', {
        requires:['Rally.ui.Button'],
        extend:'Ext.Container',
        alias:'widget.rallyiterationburndownminimalviewtoggle',
        mixins: ['Ext.state.Stateful'],

        stateEvents: ['toggle'],

        componentCls: 'toggle-button-group',
        layout: 'hbox',
        border: 1,
        activeButtonCls: 'active hide-tooltip',

        defaultType: 'rallybutton',
        items: [
            {
                itemId: 'burndown',
                cls: 'toggle left burndown',
                iconCls: 'icon-bars',
                frame: false,
                toolTipConfig: {
                    html: 'Burndown',
                    anchor: 'bottom',
                    hideDelay: 0
                },
                userAction:'IterationBurnDownMinimalApp - User clicked burndown'
            },
            {
                itemId: 'cumulativeflow',
                cls: 'toggle right cumulativeflow',
                iconCls: 'icon-graph',
                frame: false,
                toolTipConfig: {
                    html: 'Cumulative Flow',
                    anchor: 'bottom',
                    hideDelay: 0
                },
                userAction:'IterationBurnDownMinimalApp - User clicked CFD'
            }
        ],

        initComponent: function() {
            this.callParent(arguments);

            this.addEvents([
                /**
                 * @event toggle
                 * Fires when the toggle value is changed.
                 * @param {String} toggleState 'burndown' or 'cumulativeflow'.
                 */
                'toggle'
            ]);

            this.items.each(function(item) {
                this.mon(item, 'click', this._onButtonClick, this);
            }, this);
        },

        /**
         * Overridden to set initial state to default
         * if state is not retrieved from StateManager.
         */
        initState: function() {
            this.callParent(arguments);

            if (!this._activeToggle) {
                this._onButtonClick(this.getComponent('burndown'));
            }
        },

        applyState: function(state) {
            var toggleState = state.toggle, btnCmp;

            if (toggleState) {
                btnCmp = this.getComponent(toggleState);
            }

            if (!btnCmp) {
                btnCmp = this.getComponent('cumulativeflow');
            }

            this._onButtonClick(btnCmp);
        },

        getState: function() {
            return {toggle: this._activeToggle};
        },

        getToggleState: function() {
            return this._activeToggle;
        },

        _onButtonClick: function(btn) {
            var btnId = btn.getItemId();
            if (btnId !== this._activeToggle) {
                this._activeToggle = btnId;

                this.items.each(function(item) {
                    if (item === btn) {
                        if (!item.hasCls(this.activeButtonCls.split(' ')[0])) {
                            item.addCls(this.activeButtonCls);
                        }
                    } else {
                        item.removeCls(this.activeButtonCls);
                    }
                }, this);

                this.fireEvent('toggle', this._activeToggle);
            }
        }
    });
})();


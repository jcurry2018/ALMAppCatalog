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
        width: 106,
        activeButtonCls: 'active',

        defaultType: 'rallybutton',
        iterationBurndownMinimalConfig: {},

        items: [{
                itemId: 'burndown',
                cls: 'toggle left burndown',
                iconCls: 'icon-bars',
                frame: false,
                toggleGroup: 'iterationburndownminimalviewtoggle',
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
                toggleGroup: 'iterationburndownminimalviewtoggle',
                toolTipConfig: {
                    html: 'Cumulative Flow',
                    anchor: 'bottom',
                    hideDelay: 0
                },
                userAction:'IterationBurnDownMinimalApp - User clicked CFD'
            }],

        initComponent: function() {
            this.callParent(arguments);

            this.addEvents([
                /**
                 * @event toggle
                 * Fires when the toggle value is changed.
                 * @param {String} toggleState 'burndown' or 'cumulativeflow' or 'heatmap'.
                 */
                'toggle'
            ]);

            if (this.iterationBurndownMinimalConfig.heatmapEnabled) {
                this.insert(1, {
                    itemId: 'heatmap',
                    cls: 'toggle center heatmap',
                    iconCls: 'icon-pie',
                    frame: false,
                    toggleGroup: 'iterationburndownminimalviewtoggle',
                    toolTipConfig: {
                        html: 'Heatmap',
                        anchor: 'bottom',
                        hideDelay: 0
                    },
                    userAction:'IterationBurnDownMinimalApp - User clicked heatmap'
                });
            }

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
                var defaultChartType = this.iterationBurndownMinimalConfig.heatmapEnabled ? 'heatmap' : 'burndown';
                var defaultChartBtn = this.getComponent(defaultChartType);
                this._activeToggle = defaultChartBtn.getItemId();
                this._setActive(defaultChartBtn);
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
                this._setActive(btn);
                this.fireEvent('toggle', this._activeToggle);
            }
        },

        _setActive: function(btn) {
            this.items.each(function(item) {
                if (item === btn) {
                    if (!item.hasCls(this.activeButtonCls.split(' ')[0])) {
                        item.addCls(this.activeButtonCls);
                    }
                } else {
                    item.removeCls(this.activeButtonCls);
                }
            }, this);
        }
    });
})();


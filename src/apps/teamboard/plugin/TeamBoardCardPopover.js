(function() {
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.teamboard.plugin.TeamBoardCardPopover', {
        alias: 'plugin.rallyteamboardcardpopover',
        extend: 'Rally.ui.cardboard.plugin.CardPopover',
        requires: ['Rally.ui.discussion.DiscussionRichTextStreamView', 'Rally.ui.grid.Grid'],

        showAssociatedDefects: function() {
            this._showAssociatedArtifactsPopover({
                columns: ['FormattedID', 'Name', 'Severity', 'Priority', 'State', 'Owner', 'Iteration', 'Project', 'LastUpdateDate'],
                target: this.card.getEl().down('.AssociatedDefects'),
                title: 'Defects',
                type: 'Defect'
            });
        },

        showAssociatedDiscussion: function() {
            this._showAssociatedPopover({
                items: [{
                    xtype: 'rallydiscussionrichtextstreamview',
                    autoScroll: true,
                    maxHeight: 600,
                    storeConfig: {
                        context: this._getContext(),
                        filters: [{property: 'User', value: this.card.getRecord().get('_ref')}]
                    }
                }],
                target: this.card.getEl().down('.AssociatedDiscussion'),
                title: 'Discussions'
            });
        },

        showAssociatedTasks: function() {
            this._showAssociatedArtifactsPopover({
                columns: ['FormattedID', 'Name', 'State', 'Owner', 'Iteration', 'Project', 'LastUpdateDate'],
                target: this.card.getEl().down('.AssociatedTasks'),
                title: 'Tasks',
                type: 'Task'
            });
        },

        showAssociatedUserStories: function() {
            this._showAssociatedArtifactsPopover({
                columns: ['FormattedID', 'Name', 'ScheduleState', 'Owner', 'Iteration', 'Project', 'LastUpdateDate'],
                target: this.card.getEl().down('.AssociatedUserStories'),
                title: 'User Stories',
                type: 'HierarchicalRequirement'
            });
        },

        _getContext: function() {
            return {project: null};
        },

        _onPopoverDestroy: function() {
            this.card.getEl().removeCls('team-board-associated-popover-shown');
        },

        _showAssociatedArtifactsPopover: function(options) {
            this._showAssociatedPopover({
                items: [{
                    xtype: 'rallygrid',
                    columnCfgs: options.columns,
                    model: Ext.identityFn(options.type),
                    storeConfig: {
                        context: this._getContext(),
                        filters: [{property: 'Owner', value: this.card.getRecord().get('_ref')}],
                        sorters: [{property: 'LastUpdateDate', direction: 'DESC'}]
                    }
                }],
                layout: 'fit',
                maxHeight: 600,
                target: options.target,
                title: options.title
            });
        },

        _showAssociatedPopover: function(popoverConfig) {
            this.card.getEl().addCls('team-board-associated-popover-shown');
            this.popover = Ext.create('Rally.ui.popover.Popover', _.merge({
                itemId: 'teamBoardAssociatedItemsPopover',
                listeners: {
                    destroy: this._onPopoverDestroy,
                    scope: this
                },
                offsetFromTarget: [{x:0, y:-8}, {x:15, y:0}, {x:5, y:15}, {x:-15, y:0}],
                width: 900
            }, popoverConfig));
        }
    });
})();
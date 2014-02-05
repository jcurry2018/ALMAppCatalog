Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.util.UserPermissions'
]

describe 'Rally.apps.roadmapplanningboard.util.UserPermissions', ->
  helpers
    createPermissions: (config) ->
      isSubscriptionAdmin: ->
        !!config.subAdmin
      isWorkspaceAdmin: ->
        !!config.workspaceAdmin
      isProjectEditor: ->
        !!config.projectEditor

    createUserPermissions: (config) ->
      Ext.create 'Rally.apps.roadmapplanningboard.util.UserPermissions',
        workspace:
          _ref: '/workspace/1'
        permissions: @createPermissions(config)

  describe '#isUserAdmin', ->
    it 'should be true if the user is a subscription admin', ->
      userPermission = @createUserPermissions(subAdmin: true)
      expect(userPermission.isUserAdmin()).toBe true

    it 'should be true if the user is a workspace admin', ->
      userPermission = @createUserPermissions(workspaceAdmin: true)
      expect(userPermission.isUserAdmin()).toBe true

    it 'should be false if the user is not a subscription or workspace admin', ->
      userPermission = @createUserPermissions(subAdmin: false, workspaceAdmin: false)
      expect(userPermission.isUserAdmin()).toBe false


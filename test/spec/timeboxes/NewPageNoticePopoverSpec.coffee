Ext = window.Ext4 || window.Ext

Ext.require ['Rally.data.PreferenceManager']

describe 'Rally.apps.timeboxes.NewPageNoticePopover', ->
  helpers
    createDialog: ->
      @dialog = Ext.create 'Rally.apps.timeboxes.NewPageNoticePopover'

  afterEach ->
    @dialog?.destroy()

  it 'should close the dialog when the user clicks the Got It button', ->
    @createDialog()
    dialogCloseSpy = @spy @dialog, 'close'
    @dialog.down('rallycarousel').setCurrentItem(2)

    @click(css: '.got-it').then =>
      expect(dialogCloseSpy.callCount).toBe 1

  it 'should contain a carousel', ->
    @createDialog()

    expect(@dialog.down('rallycarousel')).not.toBeUndefined()
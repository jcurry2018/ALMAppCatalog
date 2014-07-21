Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.iterationtrackingboard.PrintDialog'
]

describe 'Rally.apps.iterationtrackingboard.PrintDialog', ->
  helpers
    createDialog: (options = {}) ->
      @dialog = Ext.widget
        xtype: 'iterationprogessappprintdialog'
        showWarning: options.showWarning
        timeboxScope: Ext.create 'Rally.app.TimeboxScope', record: @mom.getRecord 'iteration'
        grid:
          getStore: ->
            getSorters: -> []

    clickCancel: ->
      @click css: ".#{Ext.baseCSSPrefix}docked-bottom .#{Ext.baseCSSPrefix}btn.secondary"

    clickPrint: ->
      @click css: ".#{Ext.baseCSSPrefix}docked-bottom .#{Ext.baseCSSPrefix}btn.primary"

    createStoresAndStubAjax: ->
      record = @mom.getRecord 'userstory', values:
        DirectChildrenCount: 0
        ChildNodes:
          Defects:
            Count: 0
          Tasks:
            Count: 0
          TestCases:
            Count: 0
          Children:
            Count: 0

      recordWithChildren = @mom.getRecord 'userstory', values:
        DirectChildrenCount: 1
        ChildNodes:
          Defects:
            Count: 0
          Tasks:
            Count: 1
          TestCases:
            Count: 0
          Children:
            Count: 0

      task = @mom.getRecord 'task'

      @ajaxStub = @ajax.whenQuerying('artifact').respondWith(_.pluck [record, recordWithChildren], 'data')
      @ajaxStub.onSecondCall().returns [task.data]

  beforeEach ->
    @openStub = @stub()
    @openStub.returns {}

    @stub Rally, 'getWindow', =>
      open: @openStub

    @treeGridPrinterStub = @stub()
    Ext.define 'Rally.ui.grid.TreeGridPrinter', print: @treeGridPrinterStub

  afterEach ->
    @dialog.destroy()

  it 'should display the expected dialog', ->
    @createDialog()

    expect(css: ".#{Ext.baseCSSPrefix}header-text").toContainText 'Print'
    expect(css: ".#{Ext.baseCSSPrefix}docked-bottom .#{Ext.baseCSSPrefix}btn.primary").toContainText 'Print'
    expect(css: ".#{Ext.baseCSSPrefix}docked-bottom .#{Ext.baseCSSPrefix}btn.secondary").toContainText 'Cancel'

  it 'should hide warning dialog by default', ->
    @createDialog()

    expect(Ext.query('.print-warning.hidden').length).toEqual 1

  it 'should show warning dialog', ->
    @createDialog
      showWarning: true

    expect(Ext.query('.print-warning').length).toEqual 1
    expect(Ext.query('.print-warning.hidden').length).toEqual 0

  describe 'canceling', ->
    beforeEach ->
      @createDialog()
      @createStoresAndStubAjax()

    it 'should close the dialog', ->
      expect(Ext.ComponentQuery.query('iterationprogessappprintdialog').length).toBe 1

      @clickCancel().then =>
        expect(Ext.ComponentQuery.query('iterationprogessappprintdialog').length).toBe 0

    it 'should not print anything', ->
      @clickCancel().then =>
        expect(@ajaxStub).not.toHaveBeenCalled()
        expect(@treeGridPrinterStub).not.toHaveBeenCalled()
        expect(@openStub).not.toHaveBeenCalled()

  describe 'printing', ->
    beforeEach ->
      @createDialog()
      @createStoresAndStubAjax()

    it 'should print the tree grid', ->
      @clickPrint().then =>
        expect(@treeGridPrinterStub).toHaveBeenCalledOnce()

    it 'should print to a new window', ->
      @clickPrint().then =>
        expect(@openStub).toHaveBeenCalledOnce()

    it 'should print summary list of work items', ->
      @clickPrint().then =>
        expect(@ajaxStub).toHaveBeenCalledOnce()

    it 'should print children', ->
      @click(id: 'printDialogReportTypeIncludeChildren-inputEl').then =>
        @clickPrint().then =>
          expect(@ajaxStub).toHaveBeenCalledTwice()

Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.iterationtrackingboard.IterationTrackingTreeGrid'
  'Rally.data.wsapi.ModelBuilder'
  'Rally.test.mock.data.WsapiModelFactory'
]

describe 'Rally.apps.iterationtrackingboard.IterationTrackingTreeView', ->
  beforeEach ->
    @ajax.whenQuerying('artifact').respondWith @mom.getData('userstory')

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'rallyiterationtrackingtreegrid'

  helpers
    createTreeView: (config = {}) ->
      storeConfig =
        models: Rally.data.wsapi.ModelBuilder.buildCompositeArtifact([
          Rally.test.mock.data.WsapiModelFactory.getModel('userstory'),
          Rally.test.mock.data.WsapiModelFactory.getModel('task')
        ], Rally.environment.getContext())

      Ext.create('Rally.data.wsapi.TreeStoreBuilder').build(storeConfig).then (store) =>
        treeGrid = new Rally.apps.iterationtrackingboard.IterationTrackingTreeGrid _.defaults config,
          store:store
          renderTo: 'testDiv'
        treeGrid.getStore().load()
        treeGrid.fireEvent 'load'
        treeGrid.getView()

  it 'needs to check #getContentWidth against treeView.getMaxContentWidth when Ext is upgraded', ->
    # getContentWidth is an altered version of Ext.tree.View.getMaxContentWidth
    # so we should check to see if that method has changed and update our version
    # accordingly whenever our version of Ext is changed
    expect(Ext.getVersion().version).toBe '4.2.2.1144'

  describe '#autoSizeColumn', ->
    it 'passes allowWrapping to getContentWidth', ->
      @createTreeView().then (view) =>
        header = view.headerCt.getGridColumns()[0]
        getContentWidthStub = @stub view, 'getContentWidth'

        # passing nothing passes true
        view.autoSizeColumn header
        expect(getContentWidthStub.getCall(0).args[1]).toBe true

        # passing true passes true
        view.autoSizeColumn header, true
        expect(getContentWidthStub.getCall(1).args[1]).toBe true

        # passing false passes false
        view.autoSizeColumn header, false
        expect(getContentWidthStub.getCall(2).args[1]).toBe false

  describe '#getContentWidth', ->
    it 'sets css properties to disallow wrapping when allowWrapping is false', ->
      @createTreeView().then (view) =>
        setStyleStub = @stub Ext.dom.Element::, 'setStyle'

        header = view.headerCt.getGridColumns()[0]
        view.getContentWidth header, false

        # Ext measuring width of header title
        expect(setStyleStub.args[0]).toEqual ['text-overflow', 'clip']
        expect(setStyleStub.args[1]).toEqual ['text-overflow', '']

        # Disallow cell wrapping
        expect(setStyleStub.args[2]).toEqual ['text-overflow', 'clip']
        expect(setStyleStub.args[3]).toEqual ['white-space', 'nowrap']
        expect(setStyleStub.args[4]).toEqual ['height', '20px']

        # Reset css properties
        expect(setStyleStub.args[5]).toEqual ['height', '']
        expect(setStyleStub.args[6]).toEqual ['white-space', '']
        expect(setStyleStub.args[7]).toEqual ['text-overflow', '']

    it 'does not set css properties to disallow wrapping when allowWrapping is true', ->
      @createTreeView().then (view) =>
        setStyleStub = @stub Ext.dom.Element::, 'setStyle'

        header = view.headerCt.getGridColumns()[0]
        view.getContentWidth header

        # Ext measuring width of header title
        expect(setStyleStub.args[0]).toEqual ['text-overflow', 'clip']
        expect(setStyleStub.args[1]).toEqual ['text-overflow', '']
        expect(setStyleStub.args.length).toBe 2

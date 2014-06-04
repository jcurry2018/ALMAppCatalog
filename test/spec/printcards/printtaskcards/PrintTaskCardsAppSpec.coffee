Ext = window.Ext4 || window.Ext

describe 'Rally.apps.printcards.printtaskcards.PrintTaskCardsApp', ->
  beforeEach ->
    iterations = @mom.getData('iteration', {count: 2})
    @ajax.whenQuerying('iteration').respondWith iterations

    _.each iterations, (iteration) ->
      @ajax.whenReading('iteration', Rally.util.Ref.getOidFromRef(iteration)).respondWith iteration

    @tasks = @mom.getData('task', {count: 9})
    @ajax.whenQuerying('task').respondWith @tasks

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'printtaskcards'

  it 'should have class="pb" after each group of 4 cards', ->
    numBreaks = (@tasks.length/4)|0
    @createApp().then =>
      expect(@app.getEl().query('.pb').length).toBe numBreaks

  it 'should remove cards after changing iteration', ->
    @createApp().then =>
      expect(@app.down('#cards').getEl().query('.artifact').length).toBe @tasks.length
      @ajax.whenQuerying('task').respondWith []

      @clickLeftTimeboxButton().then =>
        expect(@app.down('#cards').getEl().query('.artifact').length).toBe 0

  helpers
    clickLeftTimeboxButton: ->
      @app.getEl().down('.combobox-left-arrow').dom.click()
      @waitForComponentReady @app

    createApp: ->
      @app = Ext.create 'Rally.apps.printcards.printtaskcards.PrintTaskCardsApp',
        renderTo: 'testDiv'
        context: @getContext()

      @waitForComponentReady @app

    getContext: ->
      globalContext = Rally.environment.getContext()

      Ext.create 'Rally.app.Context',
        initialValues:
          project:globalContext.getProject()
          workspace:globalContext.getWorkspace()
          user:globalContext.getUser()
          subscription:globalContext.getSubscription()
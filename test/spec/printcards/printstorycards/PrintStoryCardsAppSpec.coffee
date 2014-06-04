Ext = window.Ext4 || window.Ext

describe 'Rally.apps.printcards.printstorycards.PrintStoryCardsApp', ->
  beforeEach ->
    iterations = @mom.getData('iteration', {count: 2})
    @ajax.whenQuerying('iteration').respondWith iterations

    _.each iterations, (iteration) ->
      @ajax.whenReading('iteration', Rally.util.Ref.getOidFromRef(iteration)).respondWith iteration

    @stories = @mom.getData('userstory', {count: 9})
    @ajax.whenQuerying('userstory').respondWith @stories

  afterEach ->
    Rally.test.destroyComponentsOfQuery 'printstorycards'

  it 'should have class="pb" after each group of 4 cards', ->
    numBreaks = (@stories.length/4)|0
    @createApp().then =>
      expect(@app.getEl().query('.pb').length).toBe numBreaks

  it 'should remove cards after changing iteration', ->
    @createApp().then =>
      expect(@app.down('#cards').getEl().query('.artifact').length).toBe @stories.length
      @ajax.whenQuerying('userstory').respondWith []

      @clickLeftTimeboxButton().then =>
        expect(@app.down('#cards').getEl().query('.artifact').length).toBe 0

  helpers
    clickLeftTimeboxButton: ->
      @app.getEl().down('.combobox-left-arrow').dom.click()
      @waitForComponentReady @app

    createApp: ->
      @app = Ext.create 'Rally.apps.printcards.printstorycards.PrintStoryCardsApp',
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
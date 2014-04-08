Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.app.Context'
]

describe 'Rally.apps.printcards.PrintCard', ->
  afterEach ->
    Rally.test.destroyComponentsOfQuery 'printcard'

  it 'should display FormattedID for each card', ->
    @loopStories('FormattedID')

  it 'should display Name for each card', ->
    @loopStories('Name')

  it 'should display Description for each card', ->
    @loopStories('Description')

  it 'should display PlanEstimate for each card', ->
    @loopStories('PlanEstimate')

  it 'should display Owner for a card', ->
    card = @mom.getRecord('userstory')
    @createCard(card.data)
    expect(Ext.get('testDiv').down('.ownerText').dom.innerHTML).toEqual "#{card.get('Owner')._refObjectName}"

  it "should show the WorkProduct formattedID for task cards", ->
    storyFormattedID = 'US123'
    tasks = @mom.getData('Task',
      values:
        WorkProduct:
          FormattedID: storyFormattedID
    )
    @createCard(tasks[0])

    expect(Ext.get('testDiv').down('.formattedid').dom.innerHTML).toBe "#{tasks[0].FormattedID}:#{storyFormattedID}"

  it 'should display "No Owner" if no owner set', ->
    @createCard(@mom.getData('UserStory',
      values:
        Owner: null
    )[0])

    expect(Ext.get('testDiv').down('.ownerText').dom.innerHTML).toBe 'No Owner'

  it 'should display "None" if no plan estimate', ->
    @createCard(@mom.getData('UserStory',
      values:
        PlanEstimate: null
    )[0])

    expect(Ext.get('testDiv').down('.planestimate').dom.innerHTML).toBe 'None'

  helpers
    loopStories: (fieldName) ->
      cards = @mom.getRecords('userstory', {count: 5})
      for i in [0..cards.length-1]
        @createCard(cards[i].data)
      containerHtml = Ext.get('testDiv')
      for i in [0..cards.length-1]
        expect(containerHtml.query("." + (fieldName.toLowerCase()))[i].innerHTML).toEqual "#{cards[i].get(fieldName)}"

    createCard: (data) ->
      Ext.create 'Rally.apps.printcards.PrintCard',
        renderTo: 'testDiv'
        data: data
Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp'
]

describe 'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', ->

  helpers
    getPiTreeGridAppConfig: (featureEnabled) ->
      defaultSettings:
        modelNames: ['PortfolioItem/Project']
      getHeight: -> 250
      getContext: ->
        get: ->
        isFeatureEnabled: -> featureEnabled
        getScopedStateId: -> 'someStateId'

  beforeEach ->
    @ajax.whenQuerying('artifact').respondWith()

  afterEach ->
    _.invoke Ext.ComponentQuery.query('portfoliotemstreegridapp'), 'destroy'

  it 'should initialize', ->
    piTreeGridApp = Ext.create 'Rally.apps.portfolioitemstreegrid.PortfolioItemsTreeGridApp', @getPiTreeGridAppConfig(false)
    expect(Ext.isDefined(piTreeGridApp)).toBeTruthy()

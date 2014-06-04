Ext = window.Ext4 || window.Ext

describe 'Rally.apps.charts.IntegrationHeaders', ->

  it 'doesn\'t pass in nulls', ->
    chartApp =
      integrationHeaders :
        nullValue : null
        notNullValue : "notNull"
    headers = Ext.create 'Rally.apps.charts.IntegrationHeaders', chartApp
    storeConfig = {}
    headers.applyTo storeConfig

    expect(storeConfig.headers['notNullValue']).toBe "notNull"
    expect(storeConfig.headers['nullValue']).toBe undefined

  it 'handles all six rally integration headers', ->
    chartApp =
      integrationHeaders :
        ignored: "Ignored"

    headers = Ext.create 'Rally.apps.charts.IntegrationHeaders',
      chartApp

    headers.withName "Trever"
    headers.withVendor "A Vendor"
    headers.withPlatform "A Platform"
    headers.withOS "windows, hardly"
    headers.withLibrary "of congress"
    headers.withVersion "3.0"

    storeConfig = {}
    headers.applyTo storeConfig

    expect(storeConfig.headers['X-RallyIntegrationName']).toBe "Trever"
    expect(storeConfig.headers['X-RallyIntegrationVendor']).toBe "A Vendor"
    expect(storeConfig.headers['X-RallyIntegrationVersion']).toBe "3.0"
    expect(storeConfig.headers['X-RallyIntegrationLibrary']).toBe "of congress"
    expect(storeConfig.headers['X-RallyIntegrationPlatform']).toBe "A Platform"
    expect(storeConfig.headers['X-RallyIntegrationOS']).toBe "windows, hardly"


  it 'allows custom keys to be passed in as well', ->
    chartApp1 =
      integrationHeaders :
        myKey: "My Value"


    headers = Ext.create 'Rally.apps.charts.IntegrationHeaders',
      chartApp1

    storeConfig = {}
    headers.applyTo(storeConfig)

    expect(storeConfig.headers['myKey']).toBe "My Value"




  it 'has meaningful defaults', ->
    chartApp2 =
      integrationHeaders :
        myKey: "My Value"

    headers = Ext.create 'Rally.apps.charts.IntegrationHeaders', chartApp2

    storeConfig = {}
    headers.applyTo(storeConfig)

    expect(storeConfig.headers['X-RallyIntegrationVendor']).toBe "Rally Software"
    expect(storeConfig.headers['X-RallyIntegrationName']).toBe "A2 Chart"

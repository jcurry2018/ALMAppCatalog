Ext = window.Ext4 || window.Ext

Ext.define 'Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory',

  singleton: true
  
  requires: [
    'Rally.data.Store'
    'Rally.test.mock.data.WsapiModelFactory'
    'Rally.apps.roadmapplanningboard.AppModelFactory'
  ]

  getRoadmapStoreFixture: ->
    @roadmapStoreFixture = Ext.create 'Rally.data.Store',
      model: Rally.apps.roadmapplanningboard.AppModelFactory.getRoadmapModel()
      proxy:
        type: 'memory'

      data: [
          id: "roadmap-id-1"
          Name: "My Roadmap"
          ref: "http://localhost:8090/plan-service/api/plan/roadmap-id-1"
          plans: [
            id: "513617ecef8623df1391fefc"
          ,
            id: "513617f7ef8623df1391fefd"
          ,
            id: "51361807ef8623df1391fefe"
          ]
        ,
          id: "77"
          Name: "test"
          ref: "test"
          plans: [
            id: "3"
          ,
            id: "rgreaesrgsrdbsrdghsrgsrese" #non-existent plan
          ]
      ]

    @roadmapStoreFixture.model.setProxy 'memory'
    @roadmapStoreFixture

  getPlanStoreFixture: ->
    @planStoreFixture = Ext.create 'Rally.data.Store',
      model: Rally.apps.roadmapplanningboard.AppModelFactory.getPlanModel()
      proxy:
        type: 'memory'
      data: [
        id: "513617ecef8623df1391fefc"
        ref: "http://localhost:8090/plan-service/api/plan/513617ecef8623df1391fefc"
        lowCapacity: 2
        highCapacity: 8
        Name: "Release 1.1"
        theme: "Take over the world!"
        roadmap:
          id: 'roadmap-id-1'
        timeframe:
          id: "2"
        features: [
          id: "F1000"
        ,
          id: "F1001"
        ,
          id: "F1002"
        ]
      ,
        id: "513617f7ef8623df1391fefd"
        ref: "http://localhost:8090/plan-service/api/plan/513617f7ef8623df1391fefd"
        lowCapacity: 3
        highCapacity: 30
        Name: "Release 1.2"
        theme: "Win Foosball Championship"
        timeframe:
          id: "3"
        roadmap:
          id: 'roadmap-id-1'
        features: [
          id: "F1005"
        ,
          id: "F1006"
        ]
      ,
        id: "51361807ef8623df1391fefe"
        ref: "http://localhost:8090/plan-service/api/plan/51361807ef8623df1391fefe"
        lowCapacity: 15
        highCapacity: 25
        Name: "Release 2.0"
        timeframe:
          id: "4"
        roadmap:
          id: 'roadmap-id-1'
        features: []
      ,
        id: "3"
        ref: "http://localhost:8090/plan-service/api/plan/3"
        lowCapacity: 0
        highCapacity: 0
        Name: " "
        timeframe:
          id: "7"
        features: []
      ]

    @planStoreFixture.model.setProxy 'memory'
    @planStoreFixture

  featureStoreData: [
    ObjectID: "1000"
    _refObjectUUID: "F1000"
    _ref: '/portfolioitem/feature/1000'
    Name: "Android Support"
    PreliminaryEstimate: {Value: 4,_refObjectName: "L"}
    RefinedEstimate: 5
    subscriptionId: "1"
    Project: {_refObjectName: "My Project"}
    Parent: {_refObjectName: "Who's Your Daddy", FormattedID: "I1"}
    LeafStoryCount: 42
    DirectChildrenCount: 39
    DragAndDropRank: 'a'
  ,
    ObjectID: "1001"
    _refObjectUUID: "F1001"
    _ref: '/portfolioitem/feature/1001'
    Name: "iOS Support"
    PreliminaryEstimate: {Value: 2,_refObjectName: "L"}
    RefinedEstimate: 4
    subscriptionId: "1"
    Project: {_refObjectName: "My Project"}
    Parent: {_refObjectName: "Who's Your Daddy", FormattedID: "I1"}
    LeafStoryCount: 42
    DirectChildrenCount: 39
    DragAndDropRank: 'b'
  ,
    ObjectID: "1002"
    _refObjectUUID: "F1002"
    _ref: '/portfolioitem/feature/1002'
    Name: "HTML 5 Webapp"
    PreliminaryEstimate: {Value: 3,_refObjectName: "L"}
    RefinedEstimate: 3
    subscriptionId: "1"
    Project: {_refObjectName: "My Project"}
    Parent: {_refObjectName: "Who's Your Daddy", FormattedID: "I1"}
    LeafStoryCount: 42
    DirectChildrenCount: 39
    DragAndDropRank: 'c'
  ,
    ObjectID: "1003"
    _refObjectUUID: "F1003"
    _ref: '/portfolioitem/feature/1003'
    Name: "Blackberry Native App"
    PreliminaryEstimate: {Value: 1,_refObjectName: "L"}
    RefinedEstimate: 2
    subscriptionId: "1"
    Project: {_refObjectName: "My Project"}
    Parent: {_refObjectName: "Who's Your Daddy", FormattedID: "I1"}
    LeafStoryCount: 42
    DirectChildrenCount: 39
    DragAndDropRank: 'd'
  ,
    ObjectID: "1004"
    _refObjectUUID: "F1004"
    _ref: '/portfolioitem/feature/1004'
    Name: "Windows Phone Support"
    PreliminaryEstimate: {Value: 3,_refObjectName: "L"}
    RefinedEstimate: 1
    subscriptionId: "2"
    Project: {_refObjectName: "My Project"}
    Parent: {_refObjectName: "Who's Your Daddy", FormattedID: "I1"}
    LeafStoryCount: 42
    DirectChildrenCount: 39
    DragAndDropRank: 'e'
  ,
    ObjectID: "1005"
    _refObjectUUID: "F1005"
    _ref: '/portfolioitem/feature/1005'
    Name: "Ubuntu Phone Application"
    PreliminaryEstimate: {Value: 4,_refObjectName: "L"}
    RefinedEstimate: 0
    subscriptionId: "2"
    Project: {_refObjectName: "My Project"}
    Parent: {_refObjectName: "Who's Your Daddy", FormattedID: "I1"}
    LeafStoryCount: 42
    DirectChildrenCount: 39
    DragAndDropRank: 'f'
  ,
    ObjectID: "1006"
    _refObjectUUID: "F1006"
    _ref: '/portfolioitem/feature/1006'
    Name: "Tester's Large Test Card 1"
    PreliminaryEstimate: {Value: 13,_refObjectName: "L"}
    RefinedEstimate: 0
    subscriptionId: "2"
    Project: {_refObjectName: "My Project"}
    Parent: {_refObjectName: "Who's Your Daddy", FormattedID: "I1"}
    LeafStoryCount: 42
    DirectChildrenCount: 39
    DragAndDropRank: 'g'
  ,
    ObjectID: "1007"
    _refObjectUUID: "F1007"
    _ref: '/portfolioitem/feature/1007'
    Name: "Tester's Large Test Card 2"
    PreliminaryEstimate: {Value: 21,_refObjectName: "L"}
    RefinedEstimate: 0
    subscriptionId: "2"
    Project: {_refObjectName: "My Project"}
    Parent: {_refObjectName: "Who's Your Daddy", FormattedID: "I1"}
    LeafStoryCount: 42
    DirectChildrenCount: 39
    DragAndDropRank: 'h'
  ,
    ObjectID: "1008"
    _refObjectUUID: "F1008"
    _ref: '/portfolioitem/feature/1008'
    Name: "Tester's Large Test Card 3"
    PreliminaryEstimate: {Value: 13,_refObjectName: "L"}
    RefinedEstimate: 0
    subscriptionId: "2"
    Project: {_refObjectName: "My Project"}
    Parent: {_refObjectName: "Who's Your Daddy", FormattedID: "I1"}
    LeafStoryCount: 42
    DirectChildrenCount: 39
    DragAndDropRank: 'i'
  ,
    ObjectID: "1009"
    _refObjectUUID: "F1009"
    _ref: '/portfolioitem/feature/1009'
    Name: "Tester's Large Test Card 4"
    PreliminaryEstimate: {Value: 8,_refObjectName: "L"}
    RefinedEstimate: 0
    subscriptionId: "2"
    Project: {_refObjectName: "My Project"}
    Parent: {_refObjectName: "Who's Your Daddy", FormattedID: "I1"}
    LeafStoryCount: 42
    DirectChildrenCount: 39
    DragAndDropRank: 'j'
  ]

  getFeatureStoreFixture: ->
    @featureStoreFixture = Ext.create 'Rally.data.wsapi.Store',
      model: Rally.test.mock.data.WsapiModelFactory.getModel 'PortfolioItem/Feature'
      proxy:
        type: 'memory'

      data: Rally.test.mock.ModelObjectMother.getRecords 'PortfolioItemFeature',
        values: @featureStoreData

    @featureStoreFixture.model.setProxy 'memory'
    @featureStoreFixture

  secondFeatureStoreData: [
    ObjectID: "1010"
    _refObjectUUID: "F1010"
    _ref: '/portfolioitem/feature/1010'
    Name: "Battlestar Gallactica"
    PreliminaryEstimate: {Value: 6,_refObjectName: "L"}
    subscriptionId: "1"
  ,
    ObjectID: "1011"
    _refObjectUUID: "F1011"
    _ref: '/portfolioitem/feature/1011'
    Name: "Firefly"
    PreliminaryEstimate: {Value: 3,_refObjectName: "L"}
    subscriptionId: "1"
  ]

  getSecondFeatureStoreFixture: ->
    @secondFeatureStoreFixture = Ext.create 'Rally.data.Store',
      model: Rally.test.mock.data.WsapiModelFactory.getModel 'PortfolioItem/Feature'
      proxy:
        type: 'memory'
      data: Rally.test.mock.ModelObjectMother.getRecords 'PortfolioItemFeature',
        values: @secondFeatureStoreData

    @secondFeatureStoreFixture.model.setProxy 'memory'
    @secondFeatureStoreFixture

  getTimelineStoreFixture: ->
    @timelineStoreFixture = Ext.create 'Rally.data.Store',
      model: Rally.apps.roadmapplanningboard.AppModelFactory.getTimelineModel()
      proxy:
        type: 'memory'
      data: [
        id: 'timeline-id-1'
        timeframes: [
          id: 1
        ]
      ]

    @timelineStoreFixture.model.setProxy 'memory'
    @timelineStoreFixture

  getTimeframeStoreFixture: ->
    @timeframeStoreFixture = Ext.create 'Rally.data.Store',
      model: Rally.apps.roadmapplanningboard.AppModelFactory.getTimeframeModel()
      proxy:
        type: 'memory'
      data: [
        id: '2'
        name: 'Q1'
        startDate: new Date('1/01/2013')
        endDate: new Date('3/31/2013')
        timeline:
          id: 'timeline-id-1'
      ,
        id: '3'
        name: 'Q2'
        startDate: new Date('4/01/2013')
        endDate: new Date('6/30/2013')
        timeline:
          id: 'timeline-id-1'
      ,
        id: '4'
        name: 'Future Planning Period'
        startDate: new Date('7/01/2013')
        endDate: new Date('6/30/2099')
        timeline:
          id: 'timeline-id-1'
      ,
        id: '7'
        name: ''
        startDate: null
        endDate: null
        timeline:
          id: 'timeline-id-1'
      ,
        id: '8'
        name: 'Timeframe not linked to a plan'
        startDate: new Date('7/01/2014')
        endDate: new Date('10/31/2014')
        timeline:
          id: 'timeline-id-1'
      ]

    @timeframeStoreFixture.model.setProxy 'memory'
    @timeframeStoreFixture

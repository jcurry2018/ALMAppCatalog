Ext = window.Ext4 || window.Ext

#Need to override injector so not replaced with actual that does not have data
Ext.define 'Rally.apps.roadmapplanningboard.DeftInjector', singleton: true, init: Ext.emptyFn
Ext.define 'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper',

  singleton: true

  requires: [
    'Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory'
  ]
  constructor: (@uuidGenerator = Ext.create('Ext.data.UuidGenerator')) ->

  loadDependencies: ->
    Rally.test.mock.env.Global.setupEnvironment
      services:
        planning_service_url: 'http://localhost:9999'
        timeline_service_url: 'http://localhost:8888'

    Deft.Injector.configure
      appModelFactory:
        className: 'Rally.apps.roadmapplanningboard.AppModelFactory'

      timelineStore:
        fn: ->
          Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.getTimelineStoreFixture()

      featureStore:
        fn: ->
          Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.getFeatureStoreFixture()

      secondFeatureStore:
        fn: ->
          Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.getSecondFeatureStoreFixture()

      planStore:
        fn: ->
          Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.getPlanStoreFixture()

      timeframeStore:
        fn: ->
          Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.getTimeframeStoreFixture()

      roadmapStore:
        fn: ->
          Rally.test.apps.roadmapplanningboard.mocks.StoreFixtureFactory.getRoadmapStoreFixture()

      uuidMapper:
        fn: =>
          getUuid: (oids) =>
            if Ext.isArray(oids)
              uuids = _.map oids, => @uuidGenerator.generate()
            else
              uuids = @uuidGenerator.generate()

            deferred = Ext.create('Deft.promise.Deferred')
            deferred.resolve(uuids)
            deferred.promise

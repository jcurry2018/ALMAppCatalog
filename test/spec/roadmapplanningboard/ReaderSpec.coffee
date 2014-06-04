Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.roadmapplanningboard.Proxy'
  'Rally.apps.roadmapplanningboard.Model'
  'Rally.apps.roadmapplanningboard.Reader'
]

describe 'Rally.apps.roadmapplanningboard.Reader', ->

  describe '#readRecords', ->
    beforeEach ->
      model = Ext.define Rally.test.generateName(),
        extend: 'Rally.data.Model'
        fields: []

      @reader = Ext.create 'Rally.apps.roadmapplanningboard.Reader',
        model: model

      @stub Ext.data.reader.Json::, 'readRecords', (data) -> data

    it 'should not wrap an object that already has a root with an array', ->
      expect(@reader.readRecords({results:[{}]})).toEqual {results:[{}]}

    it 'should wrap an object in an array at the root', ->
      expect(@reader.readRecords({})).toEqual {results:[{}]}



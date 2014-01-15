Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.iterationtrackingboard.IsLeafHelper'
]

describe 'Rally.apps.iterationtrackingboard.IsLeafHelper', ->
  helpers
    createRecord: (recordType, withSubItems) ->
      record = @mom.getRecord(recordType, emptyCollections: !withSubItems) 
      record.parentNode = {}
      record

  it 'should return is not a leaf for a root node for TreeGrid', ->
    expect(Rally.apps.iterationtrackingboard.IsLeafHelper.isLeaf({})).toBe(false)

  it 'should return is a leaf for a user story with no sub items', ->
    record = @createRecord('userstory', false)
    expect(Rally.apps.iterationtrackingboard.IsLeafHelper.isLeaf(record)).toBe(true)

  it 'should return not a leaf for a user story with sub items', ->
    record = @createRecord('userstory', true)
    expect(Rally.apps.iterationtrackingboard.IsLeafHelper.isLeaf(record)).toBe(false)

  it 'should return is a leaf for a test set with no sub items', ->
    record = @createRecord('testset', false)
    expect(Rally.apps.iterationtrackingboard.IsLeafHelper.isLeaf(record)).toBe(true)

  it 'should return is not a leaf for a test set with sub items', ->
    record = @createRecord('testset', true)
    expect(Rally.apps.iterationtrackingboard.IsLeafHelper.isLeaf(record)).toBe(false)

  it 'should return is a leaf for defects with no sub items', ->
    record = @createRecord('defect', false)
    expect(Rally.apps.iterationtrackingboard.IsLeafHelper.isLeaf(record)).toBe(true)

  it 'should return is not a leaf for defects with sub items', ->
    record = @createRecord('defect', true)
    expect(Rally.apps.iterationtrackingboard.IsLeafHelper.isLeaf(record)).toBe(false)

  it 'should return is a leaf for defect suites with no sub items', ->
    record = @createRecord('defectsuite', false)
    expect(Rally.apps.iterationtrackingboard.IsLeafHelper.isLeaf(record)).toBe(true)

  it 'should return is not a leaf for defect suites with sub items', ->
    record = @createRecord('defectsuite', true)
    expect(Rally.apps.iterationtrackingboard.IsLeafHelper.isLeaf(record)).toBe(false)
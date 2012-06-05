{Query} = require '../../src/query'
{decap} = require './lib/util'

expected =
    "Employee.department": 'OUTER'
    "Employee.department.company": 'OUTER'

exports['test no Query.joins'] = (beforeExit, assert) ->
    q = new Query()
    assert.deepEqual q.joins, {}

exports['test input=output Query.joins'] = (beforeExit, assert) ->
    q = new Query root: 'Employee', joins: expected
    assert.deepEqual q.joins, expected

exports['test paths only Query.joins'] = (beforeExit, assert) ->
    asPaths = (k for k, _ of expected)
    q = new Query root: 'Employee', joins: asPaths
    assert.deepEqual q.joins, expected

exports['test headless paths Query.joins'] = (beforeExit, assert) ->
    asHeadlessPaths = (decap k for k, _ of expected)
    q = new Query root: 'Employee', joins: asHeadlessPaths
    assert.deepEqual q.joins, expected

exports['test object list Query.joins'] = (beforeExit, assert) ->
    asObjList = ({path: p, style: s} for p, s of expected)
    q = new Query root: 'Employee', joins: asObjList
    assert.deepEqual q.joins, expected

exports['test headless object list Query.joins'] = (beforeExit, assert) ->
    asHeadlessObjList = ({path: decap(p), style: s} for p, s of expected)
    q = new Query root: 'Employee', joins: asHeadlessObjList
    assert.deepEqual q.joins, expected

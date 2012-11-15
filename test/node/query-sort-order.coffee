{Query} = require '../../src/query'
{omap, fold, get}  = require '../../src/shiv'
{decap, lc} = require './lib/util'

expected = [
    {path: 'Employee.name', direction: 'DESC'},
    {path: 'Employee.age', direction: 'ASC'}
]
views = expected.map get 'path'

exports['test default sort order'] = (beforeExit, assert) ->
    q = new Query()
    assert.deepEqual q.sortOrder, []

exports['test with list of objects'] = (beforeExit, assert) ->
    q = new Query from: 'Employee', select: views, sortOrder: expected
    assert.deepEqual q.sortOrder, expected

exports['test with lower-case directions'] = (beforeExit, assert) ->
    lcdirs = expected.map omap (k, v) -> [k, if k is 'direction' then lc(v) else v]
    q = new Query from: 'Employee', select: views, sortOrder: lcdirs
    assert.deepEqual q.sortOrder, expected

exports['test with list of strings'] = (beforeExit, assert) ->
    expectedhere = expected.reverse().map omap (k, v) -> [k, if k is 'direction' then 'ASC' else v]
    q = new Query from: 'Employee', select: views, sortOrder: views.reverse()
    assert.deepEqual q.sortOrder, expectedhere

exports['test with list of pairs'] = (beforeExit, assert) ->
    pairs = expected.map (oe) -> o = {}; o[oe.path] = oe.direction; o
    q = new Query from: 'Employee', select: views, sortOrder: pairs
    assert.deepEqual q.sortOrder, expected

    q = new Query from: 'Employee', select: views, orderBy: pairs
    assert.deepEqual q.sortOrder, expected






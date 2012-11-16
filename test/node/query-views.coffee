{Query} = require '../../src/query'
{omap, fold}  = require '../../src/util'
{decap, lc} = require './lib/util'

expected = ['Gene.symbol', 'Gene.length']

exports['test no Query.views'] = (beforeExit, assert) ->
    q = new Query()
    assert.deepEqual q.views, []

exports['test as is views'] = (beforeExit, assert) ->
    q = new Query root: 'Gene', views: expected
    assert.deepEqual q.views, expected

exports['test as is views:select'] = (beforeExit, assert) ->
    q = new Query from: 'Gene', select: expected
    assert.deepEqual q.views, expected

exports['test headless views:select'] = (beforeExit, assert) ->
    q = new Query from: 'Gene', select: expected.map decap
    assert.deepEqual q.views, expected

exports['test no root views:select'] = (beforeExit, assert) ->
    q = new Query select: expected
    assert.deepEqual q.views, expected

exports['test remove views'] = (beforeExit, assert) ->
    q = new Query select: expected
    q.removeFromSelect 'Gene.symbol'
    assert.deepEqual q.views, ['Gene.length']

    q = new Query from: "Gene", select: ["symbol", "name", "length", "primaryIdentifier"]
    q.removeFromSelect ['symbol', "length"]
    assert.deepEqual q.views, ['Gene.name', 'Gene.primaryIdentifier']

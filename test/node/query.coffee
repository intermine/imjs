Query = require('../../src/query').Query

exports["test Query#new"] = (beforeExit, assert) ->
    n = 0
    try
        q = new Query()
        n++
    catch error
        console.error error

    beforeExit () ->
        assert.equal 1, n, "Can construct query"

exports['test Query.root'] = (beforeExit, assert) ->
    q = new Query root: 'Gene'
    assert.equal 'Gene', q.root
    q = new Query from: 'Gene'
    assert.equal 'Gene', q.root

exports['test Query.views'] = (beforeExit, assert) ->
    q = new Query root: 'Gene', views: ['Gene.symbol', 'Gene.length']
    assert.deepEqual q.views, ['Gene.symbol', 'Gene.length']
    q = new Query from: 'Gene', select: ['Gene.symbol', 'Gene.length']
    assert.deepEqual q.views, ['Gene.symbol', 'Gene.length']
    q = new Query from: 'Gene', select: ['symbol', 'length']
    assert.deepEqual q.views, ['Gene.symbol', 'Gene.length']
    q = new Query select: ['Gene.symbol', 'Gene.length']
    assert.deepEqual q.views, ['Gene.symbol', 'Gene.length']










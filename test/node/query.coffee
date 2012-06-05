{Query} = require '../../src/query'
{omap, fold}  = require '../../src/shiv'
{decap, lc} = require './lib/util'

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



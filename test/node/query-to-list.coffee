{asyncTest, older_emps, clearTheWay} = require './lib/service-setup'
{invoke, get, omap, fold}  = require '../../src/util'

list_opts = name: 'list-from-js-query', tags: ['foo', 'bar', 'baz', 'js', 'node', 'testing']

exports['can make a list from a query'] = asyncTest 3, (beforeExit, assert) ->
    sizeIsRight = @testCB (l) -> assert.eql 46, l.size
    hasTag = @testCB (l) -> assert.ok l.hasTag 'js'
    clearTheWay(@service, list_opts.name)
        .then(=> @service.query older_emps)
        .then(invoke 'saveAsList', list_opts)
        .done([sizeIsRight, hasTag])
        .then(invoke 'contents')
        .done(@testCB (xs) -> assert.includes (xs.map get 'name'), 'Carol')
        .always => @service.fetchList(list_opts.name).then(invoke 'del')


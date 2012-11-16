{asyncTest, older_emps, clearTheWay} = require './lib/service-setup'
{get, invoke}  = require '../../src/util'
$ = require 'underscore.deferred'

name = "temp-created_in_js-diff"
tags = ['js', 'node', 'testing']
lists = ['The great unknowns', 'some favs-some unknowns-some umlauts']

exports['can perform a list diff'] = asyncTest 4, (beforeExit, assert) ->
    setup   = => clearTheWay(@service, name)
    cleanUp = => @service.fetchList(name).then(invoke 'del')
    run     = => @service.diff( {name, lists, tags} )
        .done(@testCB (l) -> assert.eql name, l.name)
        .done(@testCB (l) -> assert.eql 4,    l.size)
        .done(@testCB (l) -> assert.ok  l.hasTag 'js')
        .then(invoke 'contents').then(invoke 'map', get 'name')
        .done @testCB (names) -> assert.includes names, 'Brenda'
    setup().then(run).always(cleanUp)

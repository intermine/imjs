{clearTheWay, asyncTest, older_emps} = require './lib/service-setup'
{invoke, omap, fold}  = require '../../src/shiv'

lists = ['My-Favourite-Employees', 'Umlaut holders']
name = 'created_in_js-union'
tags = ['js', 'node', 'testing']

exports['can perform a list union'] = asyncTest 2, (beforeExit, assert) ->
    first = clearTheWay(@service, name)
    clean = invoke 'del'
    test  = => @service.merge( {name, lists, tags} )
        .done(@testCB (l) -> assert.eql 6, l.size)
        .done(@testCB (l) -> assert.ok l.hasTag 'js')

    first.then(test).then(clean)


{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold, invoke, get}  = require '../../src/shiv'

exports['can fetch a list'] = asyncTest 1, (beforeExit, assert) ->
    @service.fetchList('My-Favourite-Employees')
        .then(get 'size').then @testCB (size) -> assert.eql 4, size

{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold, invoke, get}  = require '../../src/util'

exports['can fetch a list'] = asyncTest 1, (beforeExit, A) ->
    @service.fetchList('My-Favourite-Employees').then(get 'size').done @testCB (c) -> A.eql 4, c

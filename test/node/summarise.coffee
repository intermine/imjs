{asyncTest, older_emps} = require './lib/service-setup'
{LOG, ERR} = require './lib/util'
{get, invoke, concatMap}  = require '../../src/shiv'

sumCounts = concatMap get 'count'

exports['can summarise a path'] = asyncTest 2, (beforeExit, A) ->
    @service.query older_emps, (q) => q.summarise 'department.company.name', (items) =>
        @runTest -> A.eql 6, items.length
        @runTest -> A.eql 46, sumCounts items

exports['can summarise a path - promise'] = asyncTest 2, (beforeExit, A) ->
    @service.query(older_emps)
        .then(invoke 'summarise', 'department.company.name')
        .done(@testCB (items) -> A.eql 6, items.length)
        .done(@testCB (items) -> A.eql 46, sumCounts items)


{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold}  = require '../../src/shiv'

exports['can summarise a path'] = asyncTest 2, (beforeExit, assert) ->
    @service.query older_emps, (q) => q.summarise 'department.company.name', (items) =>
        @runTest () -> assert.eql 6, items.length
        @runTest () -> assert.eql 46, fold(0, (a, x) -> a + x.count) items


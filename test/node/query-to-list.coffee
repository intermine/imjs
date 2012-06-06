{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold}  = require '../../src/shiv'

exports['can make a list from a query'] = asyncTest 4, (beforeExit, assert) ->
    list_opts = name: 'list-from-js-query', tags: ['foo', 'bar', 'baz', 'js', 'node']
    @service.query older_emps, (q) => q.saveAsList list_opts, (l) =>
        @runTest () -> assert.eql 46, l.size
        @runTest () -> assert.ok l.hasTag 'js'
        l.contents (xs) =>
            @runTest () -> assert.includes (xs.map (x) -> x.name), 'Carol'
            l.del().done(() => @runTest () -> assert.ok true)
                   .fail(() => @runTest () -> assert.ok false)


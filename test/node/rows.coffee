{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold}  = require '../../src/shiv'

exports['can fetch rows'] = asyncTest 2, (beforeExit, assert) ->
    query = omap((k, v) -> [k, if k is 'select' then v.concat(['age']) else v]) older_emps
    @service.query query, (q) => q.rows (rows) =>
        i = q.views.length - 1
        @runTest () -> assert.eql rows.length, 46
        @runTest () -> assert.equal (fold(0, (a, x) -> a + x[i]) rows), 2688
    

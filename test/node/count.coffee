{asyncTest, older_emps} = require './lib/service-setup'

exports['can count'] = asyncTest 1, (beforeExit, assert) ->
    @service.query older_emps, (q) => q.count (c) => @runTest () -> assert.eql c, 46


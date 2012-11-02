{asyncTest, older_emps} = require './lib/service-setup'

exports['can count'] = asyncTest 1, (beforeExit, assert) ->
    @service.query older_emps, (q) => q.count (c) => @runTest () -> assert.eql c, 46

exports['can count all'] = asyncTest 1, (beforeExit, assert) ->
    @service.query select: ['*'], from: 'Employee', (q) => q.count (c) => @runTest () -> assert.ok c > 46

exports['can pipe count'] = asyncTest 1, (beforeExit, assert) ->
    fail = (args...) ->
        console.error.apply(console, args)
        @runTest -> assert.ok false
    @service.query({select: ['*'], from: 'Employee'}).fail(fail).pipe(@service.count).pipe((c) => @runTest () -> assert.ok c > 46)

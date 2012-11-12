{asyncTest, older_emps} = require './lib/service-setup'

c_is = (exp) -> (c) => @runTest => @assert.eql exp, c

exports['can count'] = asyncTest 1, ->
    @service.query older_emps, (q) => q.count (c) => @runTest => @assert.eql c, 46

exports['can count all'] = asyncTest 1, ->
    @service.query select: ['*'], from: 'Employee', (q) => q.count (c) => @runTest => @assert.ok c > 46

exports['can pipe count'] = asyncTest 1, (beforeExit, assert) ->
    @service.query(older_emps)
        .then(@service.count)
        .fail(@fail)
        .done c_is.call @, 46

exports['can lift arguments into query'] = asyncTest 1, ->
    @service.count(older_emps).fail(@fail).done c_is.call @, 46

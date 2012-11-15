{asyncTest, older_emps} = require './lib/service-setup'

all = select: ['*'], from: 'Employee'

exports['can count'] = asyncTest 1, ->
    @service.query older_emps, (q) =>
        q.count (c) =>
            @runTest =>
                @assert.eql c, 46

exports['can count all'] = asyncTest 1, ->
    @service.query all, (q) =>
        q.count (c) =>
            @runTest =>
                @assert.ok 100 < c < 150

exports['can pipe count'] = asyncTest 1, (beforeExit, assert) ->
    @service.query(older_emps)
        .then(@service.count)
        .done @testCB (c) -> assert.eql 46, c

exports['can lift arguments into query'] = asyncTest 1, ->
    @service.count(older_emps)
        .done @testCB (c) => @assert.eql 46, c

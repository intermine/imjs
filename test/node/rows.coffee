{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold, invoke}  = require '../../src/shiv'
{_} = require 'underscore'

LOG = -> console.log arguments...
add = (a, b) -> a + b

getQuery = -> omap((k, v) -> [k, if k is 'select' then v.concat(['age']) else v]) older_emps

exports['can fetch rows'] = asyncTest 2, (beforeExit, assert) ->
    @service.query getQuery(), (q) => q.rows (rows) =>
        i = q.views.length - 1
        @runTest -> assert.eql rows.length, 46
        @runTest -> assert.equal rows.map(invoke 'pop').reduce(add), 2688
    
exports['can fetch rows - promise'] = asyncTest 2, (beforeExit, assert) ->
    test = (rows) =>
        @runTest -> assert.eql rows.length, 46
        @runTest -> assert.equal rows.map(invoke 'pop').reduce(add), 2688

    @service.query(getQuery()).then(invoke 'rows').then(test, @fail)

exports['can iterate over rows'] = asyncTest 2, (beforeExit, assert) ->
    n = totalAge = 0
    doThis = (row) ->
        n++
        totalAge += row.pop()
    andFinally = =>
        @runTest -> assert.eql n, 46
        @runTest -> assert.eql totalAge, 2688

    @service.query getQuery(), (q) => q.eachRow [doThis, @fail, andFinally]

exports['can iterate over rows - promises'] = asyncTest 2, (beforeExit, assert) ->
    n = totalAge = 0
    checkTotals = =>
        @runTest -> assert.eql n, 46
        @runTest -> assert.eql totalAge, 2688
    @service.query(getQuery()).then(invoke 'eachRow').then (iter) ->
        iter.each (row) ->
            n++
            totalAge += row.pop()
        iter.error _.compose @fail, @fail
        iter.done checkTotals

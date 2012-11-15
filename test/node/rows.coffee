{setup, asyncTestCase, older_emps} = require './lib/service-setup'
{asyncTestCase} = require './lib/util'
{set, omap, fold, invoke, flatMap}  = require '../../src/shiv'

# Helper class to incapsulate the logic for iterating testing.
class Counter
    constructor: ->
        @n = 0
        @total = 0
    count: (row) =>
        @n++
        @total += row[row.length - 1]
    checker: (assert, n, total) -> () =>
        assert.eql n, @n, "#{ @n } should be #{ n }"
        assert.eql total, @total, "#{ @total } should be #{ total }"

opts = -> omap((k, v) -> [k, if k is 'select' then v.concat(['age']) else v]) older_emps
extension = (n, total) ->
    counter: new Counter
    testCounts: (assert) -> @testCB @counter.checker assert, n, total
    testRows: (assert) -> @testCB (rows) ->
        assert.eql n, rows.length
        assert.eql total, (flatMap invoke 'pop') rows

asyncTest = asyncTestCase -> (set extension(46, 2688)) setup()

exports['can fetch rows'] = asyncTest 1, (beforeExit, assert) ->
    @service.query opts(), (q) => q.rows @testRows assert
    
exports['can fetch rows - promise'] = asyncTest 1, (beforeExit, assert) ->
    @service.query(opts()).then(invoke 'rows').then @testRows assert

exports['can lift opts to query'] = asyncTest 1, (beforeExit, assert) ->
    @service.rows(opts()).then @testRows assert

exports['can iterate over rows'] = asyncTest 1, (beforeExit, assert) ->
    @service.query opts(), (q) => q.eachRow [@counter.count, @fail, @testCounts assert]

exports['can iterate over rows single cb'] = asyncTest 1, (beforeExit, assert) ->
    @service.query opts(), (q) =>
        q.eachRow( @counter.count ).done invoke 'done', @testCounts assert

exports['can iterate over rows - promises'] = asyncTest 1, (beforeExit, assert) ->
    @service.query(opts()).then(invoke 'eachRow').then (iter) =>
        iter.each  @counter.count
        iter.done  @testCounts assert


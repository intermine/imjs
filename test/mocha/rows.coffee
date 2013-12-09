Fixture                = require './lib/fixture'
{prepare, eventually, shouldFail}  = require './lib/utils'
{invokeWith, invoke, defer, get, flatMap} = Fixture.funcutils
should = require 'should'

# Helper class to incapsulate the logic for tests on iteration
class Counter
  n: 0
  total: 0
  constructor: (@expN, @expT, done) ->
    {promise, @reject, @resolve} = defer()
    promise.then (-> done()), done
  count: (row) =>
    @n++
    @total += row[0]
  check: () =>
    try
      @n.should.equal(@expN)
      @total.should.equal(@expT)
      @resolve()
    catch e
      @reject e

  callbacks: ->
    [@count, @reject, @check]

Counter.forOlderEmployees = (done) ->
  c = new Counter 46, 2688, done
  c.callbacks()

SLOW = 100
sumRows = flatMap get 0

test = (done) -> (rows) ->
  try
    rows.should.have.lengthOf(46)
    sumRows(rows).should.equal(2688)
    done()
  catch e
    done e

describe 'Query', ->

  @slow SLOW
  {service, olderEmployees} = new Fixture()

  query =
    select: ['age']
    from: 'Employee'
    where: olderEmployees.where
  
  describe '#rows()', ->

    it 'should return 46 rows, with a sum of 2688', (done) ->
      service.query(query).then(invoke 'rows').then test(done), done

    it 'should return 46 rows, with a sum of 2688, and work with callbacks', (done) ->
      check = test done
      rowTest = invoke 'rows', (err, rows) ->
        return done err if err?
        check rows
      service.query(query).then rowTest, done

  describe '#eachRow', ->

    it 'should allow iteration per item', (done) ->
      cbs = Counter.forOlderEmployees done
      service.query(query).done invokeWith 'eachRow', cbs

    it 'should allow iteration per item with a single callback', (done) ->
      [count, error, end] = Counter.forOlderEmployees done
      testStream = (stream) ->
        stream.on 'error', error
        stream.on 'end', end
      testQuery = (q) -> q.eachRow(count).then testStream, error
      service.query(query).then testQuery, error

    it 'should allow iteration with promises', (done) ->
      [count, error, end] = Counter.forOlderEmployees done
      attach = (stream) ->
        stream.on 'data', count
        stream.on 'error', error
        stream.on 'end', end
      service.query(query).then(invoke 'eachRow').then attach, error

describe 'Service', ->
  @slow SLOW

  describe '#rows()', ->

    describe 'good requests', ->

      {service, olderEmployees} = new Fixture()

      query =
        select: ['age']
        from: 'Employee'
        where: olderEmployees.where

      it 'accepts a query options object, and can run it as it would a query', (done) ->
        check = test done
        service.rows(query).done check, done
        
      it 'accepts a query options object, and can run it, accepting callbacks', (done) ->
        check = test done
        service.rows query, (err, rows) ->
          return done err if err?
          check rows

    describe 'very short timeouts', ->

      {service, olderEmployees} = new Fixture()

      it 'should fail', shouldFail -> service.rows olderEmployees, timeout: 1

    describe 'reasonable timeouts', ->

      {service, olderEmployees} = new Fixture()

      query =
        select: ['age']
        from: 'Employee'
        where: olderEmployees.where

      it 'should succeed and get results', (done) ->
        check = test done
        service.rows(query, timeout: 2000).done check, done

    describe 'bad requests', ->

      {service, badQuery} = new Fixture()
      service.errorHandler = null

      it 'should return a failed promise', shouldFail -> service.rows badQuery

      it 'should yield an error as the first parameter to the callback', (done) ->
        service.rows badQuery, (err, rows) ->
          return done new Error("Expected error, but got #{ rows } instead") unless err?
          done()

  describe '#eachRow()', ->

    describe 'good requests', ->

      {service, olderEmployees} = new Fixture()

      query =
        select: ['age']
        from: 'Employee'
        where: olderEmployees.where

      it 'can run a query and yield each row', (done) ->
        cbs = Counter.forOlderEmployees done
        service.query(query).done (q) -> service.eachRow q, {}, cbs...

      it 'can run a query and yield each row, and does not need a page', (done) ->
        cbs = Counter.forOlderEmployees done
        service.query(query).done (q) -> service.eachRow q, cbs...

      it 'accepts a query options object and can run it as a query, callbacks', (done) ->
        cbs = Counter.forOlderEmployees done
        service.eachRow query, {}, cbs...

      it 'accepts a query options object and can run it as a query, callbacks, no page', (done) ->
        cbs = Counter.forOlderEmployees done
        service.eachRow query, cbs...

      it 'accepts a query options object and can run it as it would a query, callback', (done) ->
        [count, error, end] = Counter.forOlderEmployees done
        service.eachRow(query, count).done (stream) ->
          stream.on 'error', error
          stream.on 'end', end
          stream.resume()

      it 'accepts a query options object and can run it as it would a query, promise', (done) ->
        [count, error, end] = Counter.forOlderEmployees done
        service.eachRow(query).done (stream) ->
          stream.on 'data', count
          stream.on 'error', error
          stream.on 'end', end
          stream.resume()

    describe 'bad requests', ->

      # Takes a looong time in firefox with firebug open.
      @slow 3000
      @timeout 10000

      {service, badQuery} = new Fixture()
      service.errorHandler = null

      request = -> service.eachRow badQuery

      it 'should return a failed promise', shouldFail request

      it 'should report the status code of a bad query', (done) ->
        failed = service.eachRow badQuery
        failed.then (res) ->
          return done new Error("Should have failed")
        failed.then null, (status) ->
          try
            status.should.match /400/
            done()
          catch e
            done e

      it 'should trigger the error handler provided', (done) ->
        state = {}
        reportNoError =
          -> done(new Error("Reached end without error")) unless state.error?
        onRow = (row) -> done new Error("Expected failure, got #{ row }")
        onError = (e) ->
          state.error = e
          cancelTimeout state.to if state.to
          try
            e.should.match /XML/
            done()
          catch err
            done err
        # Sometimes end is reported before errors, so queue this event for later.
        onEnd = -> state.to = setTimeout reportNoError, 100
        service.eachRow badQuery, onRow, onError, onEnd

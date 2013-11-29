Fixture                = require './lib/fixture'
{prepare, eventually, shouldFail}  = require './lib/utils'
{invoke, get, flatMap} = Fixture.funcutils

# Helper class to incapsulate the logic for tests on iteration
class Counter
  constructor: (@expN, @expT, @done) ->
    @n = 0
    @total = 0
  count: (row) =>
    @n++
    @total += row[0]
  check: () =>
    @n.should.equal(@expN)
    @total.should.equal(@expT)
    @done()

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
      {check, count} = new Counter 46, 2688, done
      service.query(query).then (q) -> q.eachRow count, done, check

    it 'should allow iteration per item with a single callback', (done) ->
      {check, count} = new Counter 46, 2688, done
      service.query(query).then (q) ->
        q.eachRow( count ).then (stream) ->
          stream.on 'error', done
          stream.on 'end', check

    it 'should allow iteration with promises', (done) ->
      {check, count} = new Counter 46, 2688, done
      attach = (stream) ->
        stream.on 'data', count
        stream.on 'error', done
        stream.on 'end', check
      service.query(query).then(invoke 'eachRow').then attach, done

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
        {check, count} = new Counter 46, 2688, done
        service.query(query).then (q) -> service.eachRow q, {}, count, done, check

      it 'can run a query and yield each row, and does not need a page', (done) ->
        {check, count} = new Counter 46, 2688, done
        service.query(query).then (q) -> service.eachRow q, count, done, check

      it 'accepts a query options object and can run it as it would a query, callbacks', (done) ->
        {check, count} = new Counter 46, 2688, done
        service.eachRow(query, {}, count, done, check)

      it 'accepts a query options object and can run it as it would a query, callbacks, no page',
        (done) ->
          {check, count} = new Counter 46, 2688, done
          service.eachRow(query, count, done, check)

      it 'accepts a query options object and can run it as it would a query, callback', (done) ->
        {check, count} = new Counter 46, 2688, done
        service.eachRow(query, count).then (stream) ->
          stream.on 'error', done
          stream.on 'end', check
          stream.resume()

      it 'accepts a query options object and can run it as it would a query, promise', (done) ->
        {check, count} = new Counter 46, 2688, done
        service.eachRow(query).then (stream) ->
          stream.on 'data', count
          stream.on 'error', done
          stream.on 'end', check
          stream.resume()

    describe 'bad requests', ->

      {service, badQuery} = new Fixture()
      service.errorHandler = null

      it 'should return a failed promise', shouldFail -> service.eachRow badQuery

      it 'should report the status code of a bad query', (done) ->
        failed = service.eachRow badQuery
        failed.then (res) -> done new Error("Should have failed")
        failed.then null, (status) ->
          try
            status.should.match /400/
            done()
          catch e
            done e

      it 'should trigger the error handler provided', (done) ->
        state = {}
        reportNoError = -> done(new Error("Reached end without error")) unless state.error?
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


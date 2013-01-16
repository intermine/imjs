Fixture                = require './lib/fixture'
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

test = (rows) ->
  rows.should.have.lengthOf(46)
  sumRows(rows).should.equal(2688)

describe 'Query', ->


  @slow SLOW
  {service, olderEmployees} = new Fixture()

  query =
    select: ['age']
    from: 'Employee'
    where: olderEmployees.where
  
  describe '#rows()', ->

    it 'should return 46 rows, with a sum of 2688', (done) ->
      service.query(query).then(invoke 'rows').then(test, done).done(-> done())

    it 'should return 46 rows, with a sum of 2688, and work with callbacks', (done) ->
      qPromise = service.query query, (q) ->
        q.rows( test ).then((-> done()), done)
      qPromise.fail(done)

  describe '#eachRow', ->

    it 'should allow iteration per item', (done) ->
      {check, count} = new Counter 46, 2688, done
      service.query(query).then (q) -> q.eachRow count, done, check

    it 'should allow iteration per item with a single callback', (done) ->
      {check, count} = new Counter 46, 2688, done
      service.query(query).then (q) ->
        q.eachRow( count ).done invoke 'done', check

    it 'should allow iteration with promises', (done) ->
      {check, count} = new Counter 46, 2688, done
      service.query(query).then(invoke 'eachRow').fail(done).then (iter) ->
        iter.each count
        iter.done check

describe 'Service', ->
  @slow SLOW

  {service, olderEmployees} = new Fixture()

  query =
    select: ['age']
    from: 'Employee'
    where: olderEmployees.where

  describe '#rows()', ->

    it 'accepts a query options object, and can run it as it would a query', (done) ->
      service.rows(query).then(test, done).always -> done()
      
    it 'accepts a query options object, and can run it, accepting callbacks', (done) ->
      resPromise = service.rows query, test
      resPromise.fail(done).done -> done()



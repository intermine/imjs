Fixture              = require './lib/fixture'
{prepare, eventually, always, shouldBeRejected} = require './lib/utils'
should               = require 'should'

{defer, invoke} = Fixture.funcutils

# Helper class to incapsulate the logic for tests on iteration
class Counter
  n: 0
  total: 0

  constructor: (@expN, @expT, @resolve, @reject) ->

  count: (emp) =>
    @n = @n + 1
    @total = @total + emp.age

  check: () =>
    try
      @n.should.equal(@expN)
      @total.should.equal(@expT)
      @resolve()
    catch e
      @reject e

Counter.forOldEmployees = (done) ->
  {promise, resolve, reject} = defer()
  promise.then (-> done()), ((e) -> done e)
  new Counter 46, 2688, resolve, reject

SLOW = 100

checkEmployees = (employees) ->
  should.exist employees
  employees.length.should.equal 46
  (e.age for e in employees).reduce((x, y) -> x + y).should.equal 2688

describe 'Service', ->
  @slow SLOW

  {olderEmployees} = new Fixture()

  olderEmployees.select.push 'age'

  describe '#records', ->

    {service} = new Fixture()

    @beforeAll prepare -> service.records olderEmployees

    it 'promises to return a list of employee records', eventually checkEmployees

  describe 'bad requests to #records', ->

    {service, badQuery} = new Fixture()
    service.errorHandler = null

    querying = service.records badQuery

    it 'should fail', shouldBeRejected querying

  describe '#records with callbacks', ->

    describe 'good requests', ->

      {service} = new Fixture()

      it 'yields a list of employee records', (done) ->
        service.records olderEmployees, (err, employees) ->
          return done err if err?
          try
            checkEmployees employees
            done()
          catch e
            done e

    describe 'bad requests', ->

      {badQuery, service} = new Fixture()

      it 'yields errors in as the first parameter to the callback', (done) ->
        eh = service.errorHandler
        service.errorHandler = ->
        service.records badQuery, (err, emps) ->
          service.errorHandler = eh
          done "Expected error - got #{ emps }" unless err?
          done()


describe 'Service#eachRecord', ->

  {olderEmployees, service} = new Fixture()

  query =
    select: ['age']
    from: 'Employee'
    where: olderEmployees.where

  describe 'Params', ->

    it 'can yield each employee, using params', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      service.eachRecord query, {}, count, reject, check

    it 'can yield each employee, without needing a page, using params', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      service.eachRecord query, count, reject, check

    it 'can yield a stream of employees, using params', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      service.eachRecord(query).done (stream) ->
        stream.on 'data', count
        stream.on 'end', check
        stream.on 'error', reject

  describe 'Query', ->

    it 'can yield each employee, all parameters', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      service.query(query).done (q) -> service.eachRecord q, {}, count, reject, check

    it 'can yield each employee, without needing a page', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      testQuery = (q) -> service.eachRecord q, count, reject, check
      service.query(query).done testQuery

    it 'can yield a stream of employees, no callbacks', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      testStream = (stream) ->
        stream.on 'data', count
        stream.on 'end', check
        stream.on 'error', reject
      testQuery = (q) -> service.eachRecord(q).then testStream, reject
      service.query(query).then testQuery, reject

describe 'Query#eachRecord', ->

  {olderEmployees, service} = new Fixture()

  query =
    select: ['Employee.age']
    where: olderEmployees.where

  @beforeAll prepare -> service.query(query).then(invoke 'eachRecord')

  it 'promises to return a stream over the employees', eventually (stream) ->
    {promise, resolve, reject} = defer()
    n = sum = 0
    stream.on 'error', reject
    stream.on 'data', (e) ->
      n++
      sum += e.age
    stream.on 'end', ->
      try
        n.should.equal 46
        sum.should.equal 2688
        resolve()
      catch e
        reject e

describe 'Query', ->

  {service, olderEmployees} = new Fixture()

  olderEmployees.select.push 'age'

  describe '#records', ->

    @beforeAll prepare -> service.query(olderEmployees).then (q) -> q.records()

    it 'promises to return a list of employee records', eventually checkEmployees

  describe '#records with callbacks', ->

    it 'yields a list of employees', (done) ->
      testEmps = invoke 'records', (err, employees) ->
        return done err if err?
        try
          checkEmployees employees
          done()
        catch e
          done e

      service.query(olderEmployees).done testEmps, done





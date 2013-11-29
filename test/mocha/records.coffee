Fixture              = require './lib/fixture'
{prepare, eventually, always, shouldBeRejected} = require './lib/utils'
should               = require 'should'

{invoke} = Fixture.funcutils

# Helper class to incapsulate the logic for tests on iteration
class Counter
  constructor: (@expN, @expT, @done) ->
    @n = 0
    @total = 0
  count: (emp) =>
    @n++
    @total += emp.age
  check: () =>
    @n.should.equal(@expN)
    @total.should.equal(@expT)
    @done()

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

  describe '#eachRecord', ->

    {service} = new Fixture()
    query =
      select: ['age']
      from: 'Employee'
      where: olderEmployees.where

    it 'can yield each employee', (done) ->
      {check, count} = new Counter 46, 2688, done
      service.query(query).then (q) -> service.eachRecord q, {}, count, done, check

    it 'can yield each employee, without needing a page', (done) ->
      {check, count} = new Counter 46, 2688, done
      service.query(query).then (q) -> service.eachRecord q, count, done, check

    it 'can yield a buffered-reader for employees', (done) ->
      {check, count} = new Counter 46, 2688, done
      service.query(query).then (q) -> service.eachRecord(q).then (stream) ->
        stream.on 'data', count
        stream.on 'end', check
        stream.on 'error', done

    it 'can yield each employee, using params', (done) ->
      {check, count} = new Counter 46, 2688, done
      service.eachRecord query, {}, count, done, check

    it 'can yield each employee, without needing a page, using params', (done) ->
      {check, count} = new Counter 46, 2688, done
      service.eachRecord query, count, done, check

    it 'can yield a buffered-reader for employees, using params', (done) ->
      {check, count} = new Counter 46, 2688, done
      service.eachRecord(query).then (stream) ->
        stream.on 'data', count
        stream.on 'end', check
        stream.on 'error', done


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


  describe '#eachRecord', ->

    it 'promises to return an iterator over the employees', (done) ->
      service.query(olderEmployees).then( (q) -> q.eachRecord() ).then (stream) ->
        n = sum = 0
        stream.on 'error', done
        stream.on 'data', (e) ->
          n++
          sum += e.age
        stream.on 'end', ->
          n.should.equal 46
          sum.should.equal 2688
          done()





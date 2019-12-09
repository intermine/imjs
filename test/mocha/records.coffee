Fixture              = require './lib/fixture'
{prepare, eventually, always, shouldBeRejected} = require './lib/utils'
should               = require 'should'
{setupRecorder, stopRecorder} = require './lib/mock'
{bothTests} = require './lib/segregation'
{setupBundle} = require './lib/mock'

{invoke} = Fixture.funcutils

SLOW = 100

checkEmployees = (employees) ->
  should.exist employees
  employees.length.should.equal 46
  (e.age for e in employees).reduce((x, y) -> x + y).should.equal 2688

bothTests() && describe 'Service', ->
# bothTests() && describe '__current', ->

  setupBundle 'records.1.json'

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
        return undefined

    describe 'bad requests', ->

      {badQuery, service} = new Fixture()

      it 'yields errors in as the first parameter to the callback', (done) ->
        eh = service.errorHandler
        service.errorHandler = ->
        service.records badQuery, (err, emps) ->
          service.errorHandler = eh
          done "Expected error - got #{ emps }" unless err?
          done()
        return undefined

bothTests() && describe 'Query', ->
# bothTests() && describe '__current', ->

  setupBundle 'records.2.json'
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

      service.query(olderEmployees).then testEmps, done
      return undefined

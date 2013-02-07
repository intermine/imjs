Fixture              = require './lib/fixture'
{prepare, eventually, always} = require './lib/utils'
should               = require 'should'

describe 'Service', ->

  {service, olderEmployees} = new Fixture()

  olderEmployees.select.push 'age'

  describe '#records', ->

    @beforeAll prepare -> service.records olderEmployees

    it 'promises to return a list of employee records', eventually (employees) ->
      should.exist employees
      employees.length.should.equal 46
      (e.age for e in employees).reduce((x, y) -> x + y).should.equal 2688

describe 'Query', ->

  {service, olderEmployees} = new Fixture()

  olderEmployees.select.push 'age'

  describe '#records', ->

    @beforeAll prepare -> service.query(olderEmployees).then (q) -> q.records()

    it 'promises to return a list of employee records', eventually (employees) ->
      should.exist employees
      employees.length.should.equal 46
      (e.age for e in employees).reduce((x, y) -> x + y).should.equal 2688

  describe '#eachRecord', ->

    it 'promises to return an iterator over the employees', (done) ->
      service.query(olderEmployees).then( (q) -> q.eachRecord() ).then (iterator) ->
        n = sum = 0
        iterator.error done
        iterator.each (e) ->
          n++
          sum += e.age
        iterator.done ->
          n.should.equal 46
          sum.should.equal 2688
          done()


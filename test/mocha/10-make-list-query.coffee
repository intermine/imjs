{prepare, eventually, always, clear, report} = require './lib/utils'
Fixture = require './lib/fixture'
{unitTests} = require './lib/segregation'
{setupBundle} = require './lib/mock'
fs = require 'fs'

unitTests() && describe 'Query#selectPreservingImpliedConstraints', ->

  {service, youngerEmployees} = new Fixture()

  setupBundle '10-make-list-query.1.json'
  @beforeAll prepare ->
    service.query(youngerEmployees).then (q) ->
      q.selectPreservingImpliedConstraints ['name', 'department.name']
    
  it 'should have the view we asked for', eventually (lq) ->
    lq.views.length.should.eql 2
    lq.views.should.containEql 'Employee.name'
    lq.views.should.containEql 'Employee.department.name'

  it 'should leave us with more constraints', eventually (lq) ->
    lq.constraints.length.should.be.above 1

  it 'should still think Employee.address is in the query', eventually (lq) ->
    lq.isInQuery('address').should.be.true

unitTests() && describe 'Query#makeListQuery', ->

  {service, youngerEmployees} = new Fixture()

  setupBundle '10-make-list-query.2.json'

  @beforeAll prepare ->
    service.query(youngerEmployees).then (q) -> q.makeListQuery()

  it 'should leave us with more constraints', eventually (lq) ->
    lq.constraints.length.should.be.above 1

  it 'should still think Employee.address is in the query', eventually (lq) ->
    lq.isInQuery('address').should.be.true


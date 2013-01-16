{prepare, eventually, always, clear, report} = require './lib/utils'
Fixture = require './lib/fixture'

describe 'Query#isRelevant', ->

  {service, youngerEmployees} = new Fixture()

  @beforeAll prepare -> service.query youngerEmployees

  it 'should find Employee.address relevant', eventually (q) ->
    q.isRelevant('address').should.be.true

  it 'should find Employee.age relevant', eventually (q) ->
    q.isRelevant('age').should.be.true

  it 'should find Employee.end relevant', eventually (q) ->
    q.isRelevant('end').should.be.true

  it 'should find Employee.department.manager relevant', eventually (q) ->
    q.isRelevant('department.manager').should.be.true

  it 'should not find Employee.department.company.CEO relevant', eventually (q) ->
    q.isRelevant('department.company.CEO').should.not.be.true

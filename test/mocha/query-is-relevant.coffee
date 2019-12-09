{prepare, eventually, always, clear, report} = require './lib/utils'
Fixture = require './lib/fixture'
{unitTests} = require './lib/segregation'
{setupBundle} = require './lib/mock'

# 'isRelevant' doesn't test any specific service by testmine
unitTests() && describe 'Query#isRelevant', ->

  setupBundle 'query-is-relevant.1.json'

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

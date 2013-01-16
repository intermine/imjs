{prepare, eventually, always, clear, report} = require './lib/utils'
Fixture = require './lib/fixture'

describe 'Query#makeListQuery', ->

  {service, youngerEmployees} = new Fixture()

  @beforeAll prepare -> service.query(youngerEmployees).then (q) -> q.makeListQuery()

  it 'should leave us with more constraints', eventually (lq) ->
    lq.constraints.length.should.be.above 1

  it 'should still find Employee.address relevant', eventually (lq) ->
    lq.isRelevant('address').should.be.true


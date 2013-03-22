Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'

describe 'Query', ->

  {service, allEmployees} = new Fixture()

  describe '#fetchCode', ->

    @beforeAll prepare -> service.query(allEmployees).then (q) -> q.fetchCode 'py'

    it 'should return some code', eventually (code) ->
      code.length.should.be.above 0

  describe '#fetchCode(long-uri)', ->

    values = [0 .. 2000]

    @beforeAll prepare -> service.query(allEmployees).then (q) ->
      q.addConstraint {path: 'age', op: 'ONE OF', values}
      q.fetchCode 'py'

    it 'should return some code', eventually (code) ->
      code.length.should.be.above 1000




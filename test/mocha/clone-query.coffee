{prepare, eventually, always, clear, report} = require './lib/utils'
Fixture = require './lib/fixture'

describe 'Query#clone', ->

  {service, youngerEmployees} = new Fixture()

  @beforeAll prepare -> service.query(youngerEmployees).then (q) ->
    [q, q.clone().addToSelect('end')]

  it 'should have several views in q', eventually ([q, clone]) ->
    q.views.length.should.be.above 0

  it 'should have more views in clone', eventually ([q, clone]) ->
    clone.views.length.should.be.above q.views.length


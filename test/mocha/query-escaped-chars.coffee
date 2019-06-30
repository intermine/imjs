Fixture = require './lib/fixture'
{promising, prepare, eventually, shouldFail} = require './lib/utils'
{invoke} = Fixture.utils
{integrationTests} = require './lib/segregation'

integrationTests() && describe 'Control query for escaped chars', ->

  {service} = new Fixture()

  @beforeAll prepare -> service.count
    select: ['id']
    from: 'Employee'
    where: [ ['name', 'CONTAINS', 'Right angle bracket'] ]

  it 'should find some employees', eventually (count) ->
    count.should.eql 1

describe 'Querying for escaped values', ->

  {service} = new Fixture()

  @beforeAll prepare -> service.count
    select: ['id']
    from: 'Employee'
    where: [ ['name', 'CONTAINS', '>'] ]

  it 'should find some employees', eventually (count) ->
    count.should.eql 1

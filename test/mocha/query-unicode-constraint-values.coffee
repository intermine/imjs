Fixture = require './lib/fixture'
{promising, prepare, eventually, shouldFail} = require './lib/utils'
{invoke} = Fixture.utils
{integrationTests} = require './lib/segregation'

# Both of the tests below see the Unicode functionality of the service
# 'count' function of the library has been tested before

integrationTests() && describe 'Control query for unicode', ->

  {service} = new Fixture()

  @beforeAll prepare -> service.count
    select: ['id']
    from: 'Employee'
    where:
      'department.company.name': "Difficulties*"

  it 'should find some employees', eventually (count) ->
    count.should.eql 21

integrationTests() && describe  'Querying for unicode values', ->

  {service} = new Fixture()

  query =
    select: ['id']
    from: 'Employee'
    where:
      'department.company.name': "Difficulties Я Us"

  @beforeAll prepare -> service.count query

  it.skip 'should find some employees', eventually (count) ->
    count.should.eql 21

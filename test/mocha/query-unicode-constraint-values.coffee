Fixture = require './lib/fixture'
{promising, prepare, eventually, shouldFail} = require './lib/utils'
{invoke} = Fixture.utils

# BOTH
describe 'Control query for unicode', ->

  {service} = new Fixture()

  @beforeAll prepare -> service.count
    select: ['id']
    from: 'Employee'
    where:
      'department.company.name': "Difficulties*"

  it 'should find some employees', eventually (count) ->
    count.should.eql 21

# BOTH
describe  'Querying for unicode values', ->

  {service} = new Fixture()

  query =
    select: ['id']
    from: 'Employee'
    where:
      'department.company.name': "Difficulties Я Us"

  @beforeAll prepare -> service.count query

  it.skip 'should find some employees', eventually (count) ->
    count.should.eql 21

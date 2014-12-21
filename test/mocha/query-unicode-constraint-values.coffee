Fixture = require './lib/fixture'
{promising, prepare, eventually, shouldFail} = require './lib/utils'
{invoke} = Fixture.utils

describe 'Querying for unicode values', ->

  {service} = new Fixture()

  @beforeAll prepare -> service.count
    select: ['id']
    from: 'Employee'
    where:
      'department.company.name': "Difficulties Я Us"

  it 'should find some employees', eventually (count) ->
    count.should.eql 21

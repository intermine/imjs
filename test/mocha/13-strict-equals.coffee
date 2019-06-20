Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'
{unitTests} = require './lib/segregation'

unitTests() && describe 'Equality', ->

  {service} = new Fixture()

  describe 'Case insensitivity', ->

    # MOCK HERE
    @beforeAll prepare -> service.count select: ['Employee.*'], where: {name: {'=': 'brenda'}}

    it 'should find something', eventually (c) -> c.should.equal 1

  describe 'Case sensitivity', ->

    # MOCK HERE
    @beforeAll prepare -> service.count select: ['Employee.*'], where: {name: {'==': 'brenda'}}

    it 'should find something', eventually (c) -> c.should.equal 0

Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'

describe 'Equality', ->

  {service} = new Fixture()

  describe 'Case insensitivity', ->

    @beforeAll prepare -> service.count select: ['Employee.*'], where: {name: {'=': 'brenda'}}

    it 'should find something', eventually (c) -> c.should.equal 1

  describe 'Case sensitivity', ->

    @beforeAll prepare -> service.count select: ['Employee.*'], where: {name: {'==': 'brenda'}}

    it 'should find something', eventually (c) -> c.should.equal 0

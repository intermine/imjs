Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'
{bothTests} = require './lib/segregation'
{setupBundle} = require './lib/mock'

bothTests() && describe 'Equality', ->

  setupBundle '13-strict-equals.1.json'

  {service} = new Fixture()

  describe 'Case insensitivity', ->

    @beforeAll prepare ->
      service.count select: ['Employee.*'], where: {name: {'=': 'brenda'}}
    
    it 'should find something', eventually (c) -> c.should.equal 1

  describe 'Case sensitivity', ->

    @beforeAll prepare ->
      service.count select: ['Employee.*'], where: {name: {'==': 'brenda'}}

    it 'should find something', eventually (c) -> c.should.equal 0

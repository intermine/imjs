{Service} = require './lib/fixture'
{prepare, eventually} = require './lib/utils'
should = require 'should'

describe 'legacy service', ->

  # An intentionally out-of-data service
  service = Service.connect root: 'http://www.metabolicmine.org/beta'

  describe 'Model', ->

    @beforeAll prepare -> service.fetchModel()

    it 'should be sensible', eventually (model) ->
      path = model.makePath 'Organism.name'
      should.exist path
      path.isAttribute().should.be.true
      path.getType().should.equal 'String'
  
  describe 'Value Requests', ->

    @beforeAll prepare -> service.values select: ['Organism.name']

    it 'should return good data', eventually (creatures) ->
      should.exist creatures
      creatures.should.contain 'Homo sapiens'


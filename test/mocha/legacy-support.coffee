{Service} = require './lib/fixture'
{shouldFail, prepare, eventually} = require './lib/utils'
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
      creatures.should.containEql 'Homo sapiens'

  describe 'fetch lists', ->

    @beforeAll prepare -> service.fetchLists()

    it 'should get a bunch of lists', eventually (lists) ->
      should.exist lists
      lists.length.should.be.above 0

  describe 'find list', ->

    @beforeAll prepare -> service.fetchLists().then ([list]) ->
      service.fetchList list.name

    it 'should find a list', eventually (list) ->
      should.exist list
      list.name.should.be.ok
      list.size.should.be.above 0

  describe 'finding non-existent list', ->

    it 'should fail', shouldFail -> service.fetchList 'non-existent-list'


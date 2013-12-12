Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'
{invoke, success, error} = Fixture.funcutils
should = require 'should'

serviceIs13 = (service) -> service.fetchVersion().then (v) ->
  if v >= 13 then success(service) else error('Service must be at version 13')

describe 'Query', ->

  describe 'summary of a path with nulls', ->

    {service, allEmployees} = new Fixture()

    @beforeEach prepare -> serviceIs13(service).then (s) ->
      s.query(allEmployees).then(invoke 'summarise', 'end')

    it 'should find lots of nulls', eventually ({results: [top, rest...]}) ->
      should.not.exist top.item

  describe 'Now restricting to nulls with multi-value', ->

    {service, allEmployees} = new Fixture()

    allEmployees.where = end: {'ONE OF': [null, 0, 8]}

    @beforeEach prepare -> serviceIs13(service).then (s) ->
      s.query(allEmployees).then(invoke 'summarise', 'end')

    it 'should find lots of nulls', eventually ({results: [top, rest...]}) ->
      should.not.exist top.item

    it 'should find what we asked for', eventually ({results}) ->
      results.length.should.equal 3

  describe 'Now restricting to non-nulls with multi-value constraints', ->

    {service, allEmployees} = new Fixture()

    allEmployees.where = end: {'NONE OF': [null, 0, 8]}

    @beforeEach prepare -> serviceIs13(service).then (s) ->
      s.query(allEmployees).then(invoke 'summarise', 'end')

    it 'should not find any nulls', eventually ({results}) ->
      for x in results
        should.exist x.item

    it 'should find something though', eventually ({results}) ->
      results.length.should.be.above 0



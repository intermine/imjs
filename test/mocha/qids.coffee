Fixture              = require './lib/fixture'
{prepare, eventually, always} = require './lib/utils'
should               = require 'should'
once = require('underscore.deferred').when

describe 'Query', ->

  describe 'Getting an id', ->

    {service, olderEmployees} = new Fixture()

    @beforeAll prepare -> service.query(olderEmployees).then (q) -> q.fetchQID()

    it 'should yield an id', eventually (id) ->
      should.exist id

  describe 'Getting an id for the same query twice', ->

    {service, olderEmployees} = new Fixture()

    @beforeAll prepare -> service.query(olderEmployees).then (q) ->
      once q.fetchQID(), q.fetchQID()

    it 'should have fetched the same id twice', eventually (a, b) ->
      a.should.equal b

  describe 'Getting an id for a different query should result in a different id', ->

    {service, olderEmployees, allEmployees} = new Fixture()

    promiseId = (query) -> service.query(query).then (q) -> q.fetchQID()

    @beforeAll prepare -> once promiseId(olderEmployees), promiseId(allEmployees)

    it 'should have fetched two different ids', eventually (a, b) ->
      a.should.not.equal b


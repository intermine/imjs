Fixture              = require './lib/fixture'
{needs, prepare, eventually, always} = require './lib/utils'
should               = require 'should'
Promise              = require 'promise'
{invoke} = Fixture.funcutils

once = Promise.all

atV = needs 12

describe 'Query', ->

  describe 'qids', ->

    {service, olderEmployees, allEmployees} = new Fixture()

    meetsReqs = atV service
    fetchId = (q) -> service.query(q).then invoke 'fetchQID'

    describe 'Getting an id', ->

      @beforeAll meetsReqs -> fetchId olderEmployees

      it 'should yield an id', eventually (id) ->
        should.exist id

    describe 'Getting an id for the same query twice, same object', ->

      @beforeAll meetsReqs -> service.query(olderEmployees).then (q) ->
        once q.fetchQID(), q.fetchQID()

      it 'should have fetched the same id twice', eventually ([a, b]) ->
        a.should.equal b

    describe 'Getting an id for the same query twice, different objects', ->

      @beforeAll meetsReqs -> once fetchId(olderEmployees), fetchId(olderEmployees)

      it 'should have fetched the same id twice', eventually ([a, b]) ->
        a.should.equal b

    describe 'Getting an id for a different query should result in a different id', ->

      @beforeAll meetsReqs -> once fetchId(olderEmployees), fetchId(allEmployees)

      it 'should have fetched two different ids', eventually ([a, b]) ->
        a.should.not.equal b


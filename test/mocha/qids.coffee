Fixture              = require './lib/fixture'
{needs, prepare, eventually, always} = require './lib/utils'
should               = require 'should'
{invoke, parallel}   = Fixture.funcutils
{unitTests} = require './lib/segregation'
{setupBundle} = require './lib/mock'

once = parallel

atV = needs 12

unitTests() && describe 'Query', ->

  setupBundle 'qids.1.json'

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


Fixture              = require './lib/fixture'
{prepare, eventually, always} = require './lib/utils'
should               = require 'should'
{unitTests}          = require './lib/segregation'
{setupBundle}        = require './lib/mock'

# Uses pre-existing methods of the Query class, and doesn't make any
# new request to the testmine service
unitTests() && describe 'Query', ->

  setupBundle 'paging.1.json'

  expected = [
    "Tatjana Berkel",
    "Jennifer Schirrmann",
    "Herr Fritsche",
    "Lars Lehnhoff",
    "Josef M\u00FCller",
    "Nyota N'ynagasongwa",
    "Herr Grahms",
    "Frank Montenbruck",
    "Andreas Hermann",
    "Jochen Sch\u00FCler"
  ]

  describe '#next', ->

    {service, olderEmployees} = new Fixture()

    olderEmployees.limit = 10
    olderEmployees.start = 0

    @beforeAll prepare -> service.query(olderEmployees).then (q) -> q.next()

    it 'gets the query to retrieve the next page of results', eventually (nextQuery) ->
      nextQuery.start.should.equal 10
    
    it 'should fetch the appropriate page of results', eventually (nq) ->
      nq.records().then (emps) -> (e.name for e in emps).should.eql expected

  describe '#previous', ->

    {service, olderEmployees} = new Fixture()

    olderEmployees.limit = 10
    olderEmployees.start = 20

    @beforeAll prepare -> service.query(olderEmployees).then (q) -> q.previous()

    it 'gets the query to retrieve the previous page of results', eventually (previousQuery) ->
      previousQuery.start.should.equal 10
    
    it 'should fetch the appropriate page of results', eventually (q) -> q.records().then (emps) ->
      (e.name for e in emps).should.eql expected


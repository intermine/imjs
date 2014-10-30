Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'
{invoke, get, flatMap} = Fixture.funcutils
sumCounts = flatMap get 'count'

describe 'Query', ->

  describe 'summary of numeric path', ->

    {service, olderEmployees} = new Fixture()

    getQuery = service.query olderEmployees
    summariseAge = invoke 'summarise', 'age'
    getSummary = getQuery.then summariseAge

    @beforeEach prepare -> getSummary

    it 'should have fewer than 21 buckets', eventually ({results}) ->
      results.length.should.be.below 21

    it 'should include all the results of the query', eventually ({results}) ->
      sumCounts(results).should.equal 46

    it 'should have a suitable max value', eventually ({stats}) ->
      stats.max.should.be.below 100

    it 'should have a suitable min value', eventually ({stats}) ->
      stats.min.should.be.above 49

    it 'should have a suitable total', eventually ({results, stats}) ->
      results.length.should.be.below stats.uniqueValues

  describe 'American English alias', ->

    {service, olderEmployees} = new Fixture()

    getQuery = service.query olderEmployees
    summariseAge = invoke 'summarize', 'age'
    getSummary = getQuery.then summariseAge

    @beforeEach prepare -> getSummary

    it 'should include all the results of the query', eventually ({results}) ->
      sumCounts(results).should.equal 46

  describe 'summary of string path', ->

    {service, olderEmployees} = new Fixture()

    getQuery = service.query olderEmployees
    summariseCompanyName = invoke 'summarise', 'department.company.name'
    getSummary = getQuery.then summariseCompanyName

    @beforeEach prepare -> getSummary

    it 'should have fewer than 21 buckets', eventually ({results}) ->
      results.length.should.equal 6

    it 'should include all the results of the query', eventually ({results}) ->
      sumCounts(results).should.equal 46

    it 'should contain the company names as the bucket labels', eventually ({results}) ->
      (x.item for x in results).should.containEql 'Wernham-Hogg'

    it 'should have a suitable total', eventually ({stats}) ->
      stats.uniqueValues.should.equal 6
    

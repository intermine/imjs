Fixture                = require './lib/fixture'
{prepare, eventually}  = require './lib/utils'

{get, invoke, defer}       = Fixture.funcutils

sum = (xs) -> xs.reduce (a, b) -> a + b

agesAreAllPositiveNumbers = eventually (ages) ->
  for age in ages
    age.should.be.above 0

agesSumToExpectedTotal = eventually (ages) ->
  sum(ages).should.equal 2688

test = (desc, prep) ->

  describe desc, ->

    @beforeAll prepare prep

    it 'should retrieve a list of ages', agesAreAllPositiveNumbers
    it 'should sum to 2688', agesSumToExpectedTotal

{service, olderEmployees} = new Fixture()

ageQuery =
  select: ['age']
  from: 'Employee'
  where: olderEmployees.where

describe 'Query', ->

  test '#values', -> service.query(ageQuery).then invoke 'values'

describe 'Service', ->

  describe '#values', ->

    test 'for queries', -> service.query(ageQuery).then service.values

    test 'for queries with callbacks', -> service.query(ageQuery).then (q) ->
      d = defer()
      service.values q, (err, ages) ->
        d.reject err if err?
        d.resolve ages
      return d.promise

    test 'for query parameters', -> service.values ageQuery

    test 'for query parameters with callbacks', ->
      d = defer()
      service.values ageQuery, (err, ages) ->
        d.reject err if err?
        d.resolve ages
      return d.promise

    describe 'for string paths', ->
      
      @beforeAll prepare -> service.values 'Company.name'

      it 'should find all the companies', eventually (companies) ->
        companies.should.have.a.lengthOf 7

      it 'should find Wernham-Hogg', eventually (companies) ->
        companies.should.containEql 'Wernham-Hogg'

    describe 'for object paths', ->
      
      @beforeAll prepare -> service.fetchModel()
                                   .then(invoke 'makePath', 'Company.name')
                                   .then(service.values)

      it 'should find all the companies', eventually (companies) ->
        companies.should.have.a.lengthOf 7

      it 'should find Wernham-Hogg', eventually (companies) ->
        companies.should.containEql 'Wernham-Hogg'

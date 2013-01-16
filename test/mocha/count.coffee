Fixture = require './lib/fixture'
{deferredTest, promising} = require './lib/utils'

describe 'Service#count', ->

  {service, olderEmployees, allEmployees} = new Fixture()

  it 'should find around 135 employees', promising service.count(allEmployees), (c) ->
    c.should.be.above(130).and.below(140)

  it 'should find 46 older employees', promising service.count(olderEmployees), (c) ->
    c.should.equal 46

  it 'should find 46 older employees with a query object',
    promising service.query(olderEmployees), (q) ->
      service.count(q).then deferredTest (c) -> c.should.equal 46

describe 'Query#count', ->

  {service, olderEmployees, allEmployees} = new Fixture()

  it 'should find around 135 employees', promising service.query(allEmployees), (q) ->
    q.count().then deferredTest (c) -> c.should.be.above(130).and.below(140)

  it 'should find 46 older employees', promising service.query(olderEmployees), (q) ->
    q.count().then deferredTest (c) -> c.should.equal 46


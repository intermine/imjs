Fixture = require './lib/fixture'
{deferredTest, promising, prepare, eventually, shouldFail} = require './lib/utils'

describe 'Service', ->

  {service, olderEmployees, allEmployees} = new Fixture()

  describe '#count()', ->

    it 'should fail', shouldFail service.count

  describe '#count(path)', ->

    pathCountTest = (path, n, xs) =>
      describe path, ->
        @beforeAll prepare -> service.count path

        it "should find #{ n } #{ xs }", eventually (c) ->
          c.should.equal n

    pathCountTest 'Employee',             132, 'employees'
    pathCountTest 'Employee.id',          132, 'employees'
    pathCountTest 'Employee.*',           132, 'employees'
    pathCountTest 'Employee.fullTime',      2, 'times'
    pathCountTest 'Department.employees', 132, 'employees'
    pathCountTest 'Company.name',           7, 'names'
    pathCountTest 'Company',                7, 'companies'

  describe '#count(query)', ->

    it 'should find 131 rows', promising service.count(allEmployees), (c) ->
      c.should.equal 131

    it 'should find 46 older employees', promising service.count(olderEmployees), (c) ->
      c.should.equal 46

    it 'should be able to use callbacks', (done) ->
      service.count olderEmployees, (err, c) ->
        return done err if err?
        try
          c.should.equal 46
          done()
        catch e
          done e

    it 'should find 46 older employees with a query object',
      promising service.query(olderEmployees), (q) ->
        service.count(q).then deferredTest (c) -> c.should.equal 46

describe 'Query#count', ->

  {service, olderEmployees, allEmployees} = new Fixture()

  it 'should find around 135 employees', promising service.query(allEmployees), (q) ->
    q.count().then deferredTest (c) -> c.should.be.above(130).and.below(140)

  it 'should find 46 older employees', promising service.query(olderEmployees), (q) ->
    q.count().then deferredTest (c) -> c.should.equal 46


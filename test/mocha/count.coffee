Fixture = require './lib/fixture'
{promising, prepare, eventually, shouldFail} = require './lib/utils'
{invoke} = Fixture.utils

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

    describe 'promise API', ->
      describe 'the count of all employees', ->
        @beforeAll prepare -> service.count allEmployees

        it 'should equal 131', eventually (c) -> c.should.equal 131

      describe 'the count of older employees', ->
        @beforeAll prepare -> service.count olderEmployees

        it 'should equal 46', eventually (c) -> c.should.equal 46

      describe 'using an instance of Query', ->
        @beforeAll prepare -> service.query(olderEmployees).then service.count

        it 'should still find 46 employees', eventually (c) -> c.should.equal 46

    describe 'the callback API', ->

      it 'should be more painful', (done) ->
        service.count olderEmployees, (err, c) ->
          return done err if err?
          try
            c.should.equal 46
            done()
          catch e
            done e

describe 'Query#count', ->

  {service, olderEmployees, allEmployees} = new Fixture()
  count = invoke 'count'

  it 'should find around 135 employees',
    promising service.query(allEmployees).then(count),
              (c) -> c.should.be.above(130).and.below(140)

  it 'should find 46 older employees',
    promising service.query(olderEmployees).then(count),
              (c) -> c.should.equal 46


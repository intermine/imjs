Fixture = require './lib/fixture'
{report, eventually} = require './lib/utils'
{get} = Fixture.funcutils

describe 'Service#findById', ->

    {service} = new Fixture()

    describe 'Looking for David', ->

        @beforeAll (done) ->
            q = select: ['Employee.id'], where: {name: 'David Brent'}
            report done, @promise = service.rows(q)
                .then(get 0).then(get 0)
                .then (id) -> service.findById 'Employee', id

        it 'should find someone with the right name', eventually (david) ->
            david.name.should.equal 'David Brent'

        it 'should find someone in the right department', eventually (david) ->
            david.department.name.should.equal 'Sales'

        it 'should find someone 41 years of age', eventually (david) ->
            david.age.should.equal 41

        it 'should find a full-time worker', eventually (david) ->
            david.fullTime.should.be.false

        it 'should find a manager', eventually (david) ->
            david['class'].should.equal 'Manager'

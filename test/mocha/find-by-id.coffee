Fixture = require './lib/fixture'
{report, eventually} = require './lib/utils'
{get} = Fixture.funcutils
{Deferred} = require 'underscore.deferred'

findEmployee = (service, q) ->
    service.rows(q).then((rows) -> rows[0][0]).then (id) -> service.findById 'Employee', id

describe 'Service#findById', ->

    {service} = new Fixture()

    describe 'Looking for David', ->

        q = select: ['Employee.id'], where: {name: 'David Brent'}

        describe 'using the promises API', ->

            @beforeAll (done) -> report done, @promise = findEmployee service, q

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

        describe 'using the call-back API', ->

            @beforeAll (done) -> report done, @promise = service.rows(q).then (rows) -> rows[0][0]

            it 'should find someone with the right name and age.', eventually (id) ->
                deferred = Deferred()
                service.findById 'Employee', id, (david) ->
                    try
                        david.name.should.equal 'David Brent'
                        david.age.should.equal 41
                        deferred.resolve()
                    catch e
                        deferred.reject new Error e
                return deferred.promise()
    
    describe 'Looking for B1', ->

        q = select: ['Employee.id'], where: {name: 'EmployeeB1'}
        
        @beforeAll (done) -> report done, @promise = findEmployee service, q

        it 'should find someone with the right name', eventually (david) ->
            david.name.should.equal 'EmployeeB1'

        it 'should find someone in the right department', eventually (david) ->
            david.department.name.should.equal 'DepartmentB1'

        it 'should find someone 40 years of age', eventually (david) ->
            david.age.should.equal 40

        it 'should find a full-time worker', eventually (david) ->
            david.fullTime.should.be.true

        it 'should find a manager', eventually (david) ->
            david['class'].should.equal 'CEO'


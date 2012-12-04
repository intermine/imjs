Fixture = require './lib/fixture'
should = require 'should'

# These tests are for the behaviour of the accessors
# for the static properties of an intermine.

is_usable = (value) -> () ->
    should.exist value
    value.should.have.property 'done'
    value.should.have.property 'fail'
    value.should.have.property 'then'

resolves = (promise) -> (done) ->
    promise.fail done
    promise.done ->
        true.should.be.ok
        done()

describe 'Static service properties:', ->

    {service} = new Fixture()

    describe 'the version', ->
        
        promise = service.fetchVersion()

        it 'should return a usable value', is_usable promise

        it 'should resolve successfully', resolves promise

        it 'should yield a positive value', (done) ->
            promise.done (v) -> v.should.be.above 0
            promise.always -> done()

        it 'should support callbacks', (done) ->
            p = service.fetchVersion (v) -> v.should.be.above 0
            p.always -> done()

    describe 'the model', ->

        promise = service.fetchModel()

        it 'should return a usable value', is_usable promise

        it 'should resolve successfully', resolves promise

        it 'should have the classes property', (done) ->
            promise.done (m) -> m.should.have.property 'classes'
            promise.always -> done()

        it 'should have a positive number of classes', (done) ->
            promise.done (m) -> (v for _, v of m.classes).length.should.be.ok
            promise.always -> done()

        it 'should support callbacks', (done) ->
            p = service.fetchModel (m) ->
                m.should.have.property 'classes'
            p.always -> done()

    describe 'the summary fields', ->

        expected = [
            "Employee.name",
            "Employee.department.name",
            "Employee.department.manager.name",
            "Employee.department.company.name",
            "Employee.fullTime",
            "Employee.address.address"
        ]

        promise = service.fetchSummaryFields()

        it 'should return a usable value', is_usable promise

        it 'should resolve successfully', resolves promise

        it 'should have fields for Employee', (done) ->
            promise.done (sfs) -> sfs.should.have.property 'Employee'
            promise.always(-> done())

        it 'should have the expected fields for Employee', (done) ->
            promise.done (sfs) -> sfs.Employee.should.eql expected
            promise.always(-> done())

        it 'should support callbacks', (done) ->
            p = service.fetchSummaryFields (sfs) ->
                sfs.should.have.property 'Employee'
            p.always -> done()


Fixture = require './lib/fixture'
should = require 'should'

# These tests are for the behaviour of the accessors
# for the static properties of an intermine.

is_usable = (value) -> () ->
  should.exist value
  value.should.have.property 'then'

resolves = (promise) -> (done) ->
  promise.then null, done
  promise.then ->
    true.should.be.ok
    done()

describe 'Static service properties:', ->

  {service} = new Fixture()

  describe 'the version', ->
    
    promise = service.fetchVersion()

    it 'should return a usable value', is_usable promise

    it 'should resolve successfully', resolves promise

    it 'should yield a positive value', (done) ->
      promise.then (v) ->
        v.should.be.above 0
        done()
      promise.then null, done

    it 'should support callbacks', (done) ->
      service.fetchVersion (err, v) ->
        v.should.be.above 0 if v?
        done(err)

  describe 'the model', ->

    promise = service.fetchModel()

    it 'should return a usable value', is_usable promise

    it 'should resolve successfully', resolves promise

    it 'should have the classes property', (done) ->
      promise.then (m) ->
        m.should.have.property 'classes'
        done()
      promise.then null, done

    it 'should have a positive number of classes', (done) ->
      promise.then null, done
      promise.then (m) ->
        (v for _, v of m.classes).length.should.be.ok
        done()

    it 'should support callbacks', (done) ->
      service.fetchModel (err, m) ->
        m.should.have.property 'classes' if m?
        done(err)

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
      promise.then null, done
      promise.then (sfs) ->
        sfs.should.have.property 'Employee'
        done()

    it 'should have the expected fields for Employee', (done) ->
      promise.then null, done
      promise.then (sfs) ->
        sfs.Employee.should.eql expected
        done()

    it 'should support callbacks', (done) ->
      promise.then null, done
      service.fetchSummaryFields (err, sfs) ->
        sfs.should.have.property 'Employee' if sfs?
        done(err)


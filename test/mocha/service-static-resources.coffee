Fixture = require './lib/fixture'
should = require 'should'

# These tests are for the behaviour of the accessors
# for the static properties of an intermine.

is_usable = (value) -> () ->
  should.exist value
  value.should.have.property 'fail'
  value.should.have.property 'then'

resolves = (promise) -> (done) ->
  promise.fail done
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
      promise.fail done

    it 'should support callbacks', (done) ->
      p = service.fetchVersion (v) ->
        v.should.be.above 0
        done()
      p.fail done

  describe 'the model', ->

    promise = service.fetchModel()

    it 'should return a usable value', is_usable promise

    it 'should resolve successfully', resolves promise

    it 'should have the classes property', (done) ->
      promise.then (m) ->
        m.should.have.property 'classes'
        done()
      promise.fail done

    it 'should have a positive number of classes', (done) ->
      promise.fail done
      promise.then (m) ->
        (v for _, v of m.classes).length.should.be.ok
        done()

    it 'should support callbacks', (done) ->
      p = service.fetchModel (m) ->
        m.should.have.property 'classes'
        done()
      p.fail done

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
      promise.fail done
      promise.then (sfs) ->
        sfs.should.have.property 'Employee'
        done()

    it 'should have the expected fields for Employee', (done) ->
      promise.fail done
      promise.then (sfs) ->
        sfs.Employee.should.eql expected
        done()

    it 'should support callbacks', (done) ->
      promise.fail done
      p = service.fetchSummaryFields (sfs) ->
        sfs.should.have.property 'Employee'
        done()


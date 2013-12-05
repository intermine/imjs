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
        return done err if err?
        try
          v.should.be.above 0 if v?
          done()
        catch e
          done e

  describe 'the release', ->
    
    promise = service.fetchRelease()

    it 'should return a usable value', is_usable promise

    it 'should resolve successfully', resolves promise

    it 'should equal "test"', (done) ->
      promise.then( (r) -> r.should.equal 'test' )
             .then (-> done()), done

    it 'should support callbacks', (done) ->
      service.fetchRelease (err, r) ->
        return done err if err?
        try
          r.should.equal 'test'
          done()
        catch e
          done e

  describe 'the classkeys', ->

    promise = service.fetchClassKeys()

    it 'should return a usable value', is_usable promise

    it 'should resolve successfully', resolves promise

    it 'should have the classes property', (done) ->
      promise.then( (ck) -> ck.should.have.property 'Employee' )
             .then (-> done()), done

    it 'should have a keys for employee', (done) ->
      promise.then( (ck) -> ck.Employee.should.have.lengthOf 1 )
             .then (-> done()), done

    it 'should support callbacks', (done) ->
      service.fetchRelease (err, ck) ->
        return done err if err?
        try
          ck.should.have.property 'classes' if m?
          done()
        catch e
          done e

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


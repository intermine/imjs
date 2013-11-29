{Service} = require '../../build/service'
should = require 'should'

describe 'Service', ->

  describe 'new Service', ->

    it 'should make a new service', ->
      service = new Service root: 'foo'
      should.exist service
      service.should.be.an.instanceOf Service

    it 'should require a root property', ->
      (-> new Service).should.throw()

    it 'should not alter complete root urls', ->
      service = new Service root: 'http://localhost/intermine-test/service/'
      service.root.should.equal 'http://localhost/intermine-test/service/'

    it 'should ensure root urls have a trailing slash', ->
      service = new Service root: 'http://localhost/intermine-test/service'
      service.root.should.equal 'http://localhost/intermine-test/service/'

    it 'should deal with minimal root urls', ->
      service = new Service root: 'localhost/intermine-test'
      service.root.should.equal 'http://localhost/intermine-test/service/'

  describe '.connect', ->

    it 'should serve as an alias for "new Service"', ->
      service = Service.connect root: 'localhost/intermine-test'
      should.exist service
      service.should.be.an.instanceOf Service
      service.root.should.equal 'http://localhost/intermine-test/service/'









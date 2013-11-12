Fixture = require './lib/fixture'
{cleanSlate, deferredTest, prepare, always, clear, eventually, shouldFail} = require './lib/utils'
{get, invoke} = Fixture.funcutils
should = require 'should'

describe 'Service', ->

  type = 'Employee'
  {service} = new Fixture()

  describe '#resolveIds()', ->

    it 'should fail', shouldFail service.resolveIds

  describe '#resolveIds(job)', ->

    identifiers = ['anne', 'brenda', 'carol', 'Foo Bar', 'fatou']
    @beforeAll prepare -> service.resolveIds({identifiers, type})
    @afterAll  (done) -> @promise.then(invoke 'del').always -> done()

    it 'should produce a job', eventually should.exist

    it 'should get resolved', eventually (job) -> job.poll()

    it 'should find four employees', eventually (job) ->
      job.poll().then deferredTest (results) ->
        Object.keys(results).length.should.equal 6
        Object.keys(results).should.include 'MATCH'
        Object.keys(results.MATCH).length.should.equal 4

  describe '#resolveIds(caseSensitiveJob)', ->

    identifiers = ['anne', 'Brenda', 'Carol', 'Foo Bar', 'Fatou']
    caseSensitive = true
    @beforeAll prepare -> service.resolveIds({identifiers, type, caseSensitive})
    @afterAll  (done) -> @promise.then(invoke 'del').always -> done()

    it 'should produce a job', eventually should.exist

    it 'should get resolved', eventually (job) -> job.poll()

    it 'should find three employees', eventually (job) ->
      job.poll().then deferredTest (results) ->
        Object.keys(results).length.should.equal 6
        Object.keys(results).should.include 'MATCH'
        Object.keys(results.MATCH).length.should.equal 3


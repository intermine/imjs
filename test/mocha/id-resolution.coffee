Fixture = require './lib/fixture'
{cleanSlate, deferredTest, prepare, always, clear, eventually, shouldFail} = require './lib/utils'
{fold, get, invoke} = Fixture.funcutils
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

    it 'should find four employees', eventually (job, version) ->
      job.poll().then deferredTest (results) ->
        results.allMatchIds().length.should.equal 4

    it 'should find four employee ids, which can be used', eventually (job) ->
      sumAges = (results) ->
        console.log results.allMatchIds()
        q = select: ['Employee.age'], where: {id: results.allMatchIds()}
        service.values(q).then fold (a, b) -> a + b

      job.wait().then(sumAges).then deferredTest (total) -> total.should.equal 215


  describe '#resolveIds(caseSensitiveJob)', ->

    identifiers = ['anne', 'Brenda', 'Carol', 'Foo Bar', 'Fatou']
    caseSensitive = true
    @beforeAll prepare -> service.resolveIds({identifiers, type, caseSensitive})
    @afterAll  (done) -> @promise.then(invoke 'del').always -> done()

    it 'should produce a job', eventually should.exist

    it 'should get resolved', eventually (job) -> job.poll()

    it 'should find three employees', eventually (job) ->
      job.poll().then deferredTest (results) ->
        results.allMatchIds().length.should.equal 3


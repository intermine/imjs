Fixture = require './lib/fixture'
idresolution = require '../../src/id-resolution-job'
fs = require 'fs'
{cleanSlate, deferredTest, prepare, always, clear, eventually, shouldFail} = require './lib/utils'
{fold, get, invoke} = Fixture.funcutils
should = require 'should'

describe 'IdResults', ->

  fixture = fs.readFileSync "#{ __dirname }/data/old-id-resolution-format.json", 'utf8'
  data = JSON.parse fixture
  result = new idresolution.IdResults data
  n = Object.keys(data).length

  it 'should have several matches', ->

    result.getMatches().length.should.equal n
    result.getMatchIds().length.should.equal n
    result.allMatchIds().length.should.equal n

  it 'should have fewer good matches', ->
    result.goodMatchIds().length.should.be.below n
    result.getMatches('MATCH').length.should.be.below n
    result.getMatchIds('MATCH').length.should.be.below n
    result.getMatches('MATCH').length.should.be.above 0
    result.getMatchIds('MATCH').length.should.be.above 0
    result.goodMatchIds().length.should.be.above 0

  for issue in ['DUPLICATE', 'OTHER', 'TYPE_CONVERTED']
    it "should have some #{ issue.toLowerCase() }s", ->
      result.getMatches(issue).length.should.be.above 0
      result.getMatchIds(issue).length.should.be.above 0
      result.getMatches(issue).length.should.be.below n
      result.getMatchIds(issue).length.should.be.below n
      result.getMatchIds(issue).length.should.not.equal result.goodMatchIds().length

###
describe 'CategoryResults', ->

  fixture = fs.readFileSync "#{ __dirname }/data/category-id-resolution-format.json", 'utf8'
  data = JSON.parse fixture
  result = new idresolution.CategoryResults data
  n = Object.keys(data).length

  it 'should have several matches', ->

    result.getMatches().length.should.equal n
    result.getMatchIds().length.should.equal n
    result.allMatchIds().length.should.equal n

  it 'should have fewer good matches', ->
    result.goodMatchIds().length.should.be.below n
    result.getMatches('MATCH').length.should.be.below n
    result.getMatchIds('MATCH').length.should.be.below n
    result.getMatches('MATCH').length.should.be.above 0
    result.getMatchIds('MATCH').length.should.be.above 0
    result.goodMatchIds().length.should.be.above 0

  for issue in ['DUPLICATE', 'OTHER', 'TYPE_CONVERTED']
    it "should have some #{ issue.toLowerCase() }s", ->
      result.getMatches(issue).length.should.be.above 0
      result.getMatchIds(issue).length.should.be.above 0
      result.getMatches(issue).length.should.be.below n
      result.getMatchIds(issue).length.should.be.below n
      result.getMatchIds(issue).length.should.not.equal result.goodMatchIds().length
###

cleanUp = (done) ->
  pass = -> done()
  @promise.then(invoke 'del').then pass, pass

describe 'Service', ->

  type = 'Employee'
  {service} = new Fixture()

  describe '#resolveIds()', ->

    it 'should fail', shouldFail service.resolveIds

  describe '#resolveIds(job)', ->

    identifiers = ['anne', 'brenda', 'carol', 'Foo Bar', 'fatou']
    @beforeAll prepare -> service.resolveIds({identifiers, type})
    @afterAll cleanUp

    it 'should produce a job', eventually should.exist

    it 'should get resolved', eventually (job) -> job.wait()

    it 'should find four employees', eventually (job) ->
      job.poll().then deferredTest (results) ->
        results.allMatchIds().length.should.equal 4

    it 'should find four good employees', eventually (job) ->
      job.poll().then deferredTest (results) ->
        results.goodMatchIds().length.should.equal 4

    it 'should find one unresolved identifier', eventually (job) ->
      job.wait().then deferredTest (results) ->
        results.unresolved.length.should.equal 1
        results.stats.identifiers.notFound.should.equal 1

    it 'should find four employee ids, which can be used', eventually (job) ->
      sumAges = (results) ->
        q = select: ['Employee.age'], where: {id: results.allMatchIds()}
        service.values(q).then fold (a, b) -> a + b

      job.wait().then(sumAges).then deferredTest (total) -> total.should.equal 215

  describe '#resolveIds(convertedTypes)', ->

    identifiers = ['Sales']
    @beforeAll prepare -> service.resolveIds({identifiers, type})
    @afterAll cleanUp

    it 'should produce a job', eventually should.exist

    it 'should get resolved', eventually (job) -> job.wait()

    it 'should find several employees:all', eventually (job) ->
      job.poll().then deferredTest (results) ->
        results.stats.objects.all.should.equal 18
    it 'should find several employees:issues', eventually (job) ->
      job.poll().then deferredTest (results) ->
        results.stats.objects.issues.should.equal 18
    it 'should find several employees:allMatchIds', eventually (job) ->
      job.poll().then deferredTest (results) ->
        results.allMatchIds().length.should.equal 18

    it 'should find zero good employees', eventually (job) ->
      job.poll().then deferredTest (results) ->
        results.stats.objects.matches.should.equal 0
        results.goodMatchIds().length.should.equal 0

  describe '#resolveIds(caseSensitiveJob)', ->

    identifiers = ['anne', 'Brenda', 'Carol', 'Foo Bar', 'Fatou']
    caseSensitive = true
    @beforeAll prepare -> service.resolveIds({identifiers, type, caseSensitive})
    @afterAll cleanUp

    it 'should produce a job', eventually should.exist

    it 'should get resolved', eventually (job) -> job.poll()

    it 'should find three employees', eventually (job) ->
      job.poll().then deferredTest (results) ->
        results.allMatchIds().length.should.equal 3

    it 'should increase its backoff on each poll', eventually (job) ->
      job.poll().then deferredTest (results) ->
        job.decay.should.be.above 50


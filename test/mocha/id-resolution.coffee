Fixture = require './lib/fixture'
if process.env.IMJS_COV
  covDir = '../../build-cov'
  idresolution = require covDir + '/id-resolution-job'
else
  idresolution = require '../../build/id-resolution-job'

OLD_ID_RES_FORMAT = require './data/old-id-resolution-format.json'
{cleanSlate, prepare, always, clear, eventually, shouldFail} = require './lib/utils'
{fold, get, invoke} = Fixture.funcutils
should = require 'should'

describe 'IdResults', ->

  data = OLD_ID_RES_FORMAT
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

testIDResolutionAgainst = (service, extraTests = {}) ->

  type = 'Employee'

  describe '#resolveIds()', ->

    it 'should fail', shouldFail service.resolveIds

  describe '#resolveIds(job)', ->

    identifiers = ['anne', 'brenda', 'carol', 'Foo Bar', 'fatou']
    @beforeAll prepare -> service.resolveIds({identifiers, type})
    @afterAll cleanUp

    it 'should produce a job', eventually should.exist

    it 'should get resolved', eventually (job) -> job.wait()

    it 'should report stats', eventually (job) ->
      job.wait().then (results) ->
        stats = results.getStats()
        should.exist stats
        stats.should.have.properties 'objects', 'identifiers'
        stats.identifiers.matches.should.equal 4
        stats.identifiers.issues.should.equal 0
        stats.objects.matches.should.equal 4
        stats.objects.issues.should.equal 0

    it 'should find four employees', eventually (job) ->
      job.poll().then (results) ->
        results.allMatchIds().length.should.equal 4

    it 'should find four good employees', eventually (job) ->
      job.poll().then (results) ->
        results.goodMatchIds().length.should.equal 4

    it 'should find four employee ids, which can be used', eventually (job) ->
      sumAges = (results) ->
        q = select: ['Employee.age'], where: {id: results.allMatchIds()}
        service.values(q).then fold (a, b) -> a + b

      job.wait().then(sumAges).then (total) -> total.should.equal 215

    extraTests['#resolveIds(job)']?()

  describe '#resolveIds(convertedTypes)', ->

    identifiers = ['Sales']
    @beforeAll prepare -> service.resolveIds({identifiers, type})
    @afterAll cleanUp

    it 'should produce a job', eventually should.exist

    it 'should get resolved', eventually (job) -> job.wait()

    it 'should find several employees:allMatchIds', eventually (job) ->
      job.poll().then (results) ->
        results.allMatchIds().should.have.lengthOf 18
        results.getMatchIds().should.have.lengthOf 18

    it 'should find zero good employees', eventually (job) ->
      job.poll().then (results) ->
        results.getStats('objects').matches.should.equal 0
        results.getStats('identifiers').matches.should.equal 0
        results.goodMatchIds().should.have.lengthOf 0
        results.getMatchIds('MATCH').should.have.lengthOf 0

  describe '#resolveIds(caseSensitiveJob)', ->

    identifiers = ['anne', 'Brenda', 'Carol', 'Foo Bar', 'Fatou']
    caseSensitive = true
    @beforeAll prepare -> service.resolveIds({identifiers, type, caseSensitive})
    @afterAll cleanUp

    it 'should produce a job', eventually should.exist

    it 'should get resolved', eventually (job) -> job.poll()

    it 'should find three employees', eventually (job) ->
      job.poll().then (results) ->
        results.allMatchIds().length.should.equal 3

    it 'should increase its backoff on each poll', eventually (job) ->
      job.poll().then (results) ->
        job.decay.should.be.above 50


describe 'Service', ->

  describe 'current', ->
    {service} = new Fixture()

    testIDResolutionAgainst service,
      '#resolveIds(job)': ->
        it 'should find one unresolved identifier', eventually (job) ->
          job.wait().then (results) ->
            results.unresolved.length.should.equal 1
            results.stats.identifiers.notFound.should.equal 1
      '#resolveIds(convertedTypes)': ->
        it 'should find several employees:all', eventually (job) ->
          job.poll().then (results) ->
            results.stats.objects.all.should.equal 18
        it 'should find several employees:issues', eventually (job) ->
          job.poll().then (results) ->
            results.stats.objects.issues.should.equal 18

  describe 'legacy', ->
    {legacy} = new Fixture()

    testIDResolutionAgainst legacy


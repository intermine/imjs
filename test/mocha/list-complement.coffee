Fixture = require './lib/fixture'
{cleanSlate, prepare, always, clear, eventually, shouldFail} = require './lib/utils'
{get, invoke} = Fixture.funcutils
should = require 'should'
{setupMock, setupBundle} = require './lib/mock'
{bothTests} = require './lib/segregation'

tags = ['js', 'testing', 'mocha', 'imjs']
namePrefix = 'temp-testing-list-operations-'

bothTests() && describe 'Service', ->
  setupMock '/service/version', 'GET'
  setupMock '/service/version', 'GET'
  setupMock '/service/version', 'GET'
  setupMock '/service/version', 'GET'
  setupMock '/service/version', 'GET'

  {service} = new Fixture()
  service.errorHandler = ->

  @slow 500
  @beforeAll cleanSlate service

  describe '#complement()', ->

    it 'should fail', shouldFail service.complement

  describe '#complement(opts)', ->

    opts =
      from: 'some favs-some unknowns'
      exclude: 'My-Favourite-Employees'
      tags: tags
      name: 'List created from subtraction'
    expectedMember = 'Brenda'
    clearUp = clear service, opts.name

    setupMock '/service/version', 'GET'
    setupBundle 'list-complement.1.json'
    @beforeAll prepare -> clearUp().then -> service.complement opts
    @afterAll always clearUp

    it 'should have succeeded', eventually -> true

    it 'should yield a list', eventually (list) ->
      should.exist list

    it 'should have the right name', eventually (list) ->
      list.name.should.equal opts.name

    it 'should have the right number of members', eventually (list) ->
      list.size.should.equal 2

    it 'should have the correct tags', eventually (list) ->
      list.hasTag(t).should.be.true for t in tags

    it "should contain #{expectedMember }", eventually (list) ->
      list.contents().then (members) ->
        (m.name for m in members).should.containEql expectedMember

  describe '#complement(opts) {Array of list names}', ->

    opts =
      from: ['some favs-some unknowns', 'Umlaut holders']
      exclude: ['My-Favourite-Employees', 'The great unknowns']
      tags: tags
      name: 'List created from subtraction of arrays of names'
    expectedMember = 'Frank Möllers'
    clearUp = clear service, opts.name

    setupMock '/service/version', 'GET'
    setupBundle 'list-complement.2.json'
    @beforeAll prepare -> clearUp().then -> service.complement opts
    @afterAll always clearUp

    it 'should have succeeded', eventually -> true

    it 'should yield a list', eventually (list) ->
      should.exist list

    it 'should have the right name', eventually (list) ->
      list.name.should.equal opts.name

    it 'should have the right number of members', eventually (list) ->
      list.size.should.equal 2

    it 'should have the correct tags', eventually (list) ->
      list.hasTag(t).should.be.true for t in tags

    it "should contain #{expectedMember }", eventually (list) ->
      list.contents().then (members) ->
        (m.name for m in members).should.containEql expectedMember

  # BOTH
  describe '#complement(opts) {Array of Lists}', ->

    from = ['some favs-some unknowns', 'Umlaut holders']
    exclude = ['My-Favourite-Employees', 'The great unknowns']
    opts =
      tags: tags
      name: 'List created from subtraction of arrays of names'
    expectedMember = 'Frank Möllers'
    clearUp = clear service, opts.name

    setup = (lists) ->
      opts.from = (l for l in lists when l.name in from)
      opts.exclude = (l for l in lists when l.name in exclude)
      service.complement opts

    setupMock '/service/version', 'GET'
    setupBundle 'list-complement.3.json'
    @beforeAll prepare -> clearUp().then( -> service.fetchLists() ).then setup

    @afterAll always clearUp

    it 'should have succeeded', eventually -> true

    it 'should yield a list', eventually (list) -> should.exist list

    it 'should have the right name', eventually (list) -> list.name.should.equal opts.name

    it 'should have the right number of members', eventually (list) ->
      list.size.should.equal 2

    it 'should have the correct tags', eventually (list) ->
      list.hasTag(t).should.be.true for t in tags

    it "should contain #{expectedMember }", eventually (list) ->
      list.contents().then (members) ->
        (m.name for m in members).should.containEql expectedMember

  describe '#complement(opts, cb)', ->
    opts =
      from: ['some favs-some unknowns', 'Umlaut holders']
      exclude: ['My-Favourite-Employees', 'The great unknowns']
      tags: tags
      name: 'List created from subtraction of arrays of names'
    clearUp = clear service, opts.name

    setupMock '/service/version', 'GET'
    setupBundle 'list-complement.4.json'
    @beforeAll prepare clearUp
    @afterAll always clearUp

    it 'should support the callback API', (done) ->
      service.complement opts, (err, list) ->
        return done err if err?
        try
          should.exist list
          list.name.should.equal opts.name
          list.size.should.equal 2
          list.hasTag(t).should.be.true for t in tags
          done()
        catch e
          done e
      return undefined


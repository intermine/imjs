should = require 'should'
{shouldBeRejected} = require './lib/utils'

Fixture = require './lib/fixture'
nock = require 'nock'

{Registry} = Fixture

# BOTH
describe 'Registry', ->

  describe 'new Registry', ->
    registry = new Registry

    it 'should make a new registry adapter', ->
      should.exist registry
      registry.should.be.an.instanceOf Registry

    describe 'getFormat', ->
      {getFormat} = new Registry
      it 'should return format of query and default back to json', ->

        getFormat().should.equal 'json'
        getFormat('xml').should.equal 'xml'

    describe 'makePath', ->
      {makePath} = new Registry

      it 'should return complete path, assembling root url and query parameters', ->
        root = makePath '', {}
        root.should.equal 'http://registry.intermine.org/service/'
        (makePath 'outer/inner', {}).should.equal "#{root}outer/inner"
        (makePath 'outer/inner', {a: 2, b: 3}).should.equal "#{root}outer/inner?a=2&b=3"

    describe 'isEmpty', ->
      {isEmpty} = new Registry

      it 'should return true if an object is empty and has Object as prototype, false if not', ->
        (isEmpty {}).should.be.true
        (isEmpty {a: 1}).should.be.false

    describe 'fetchMines', ->
      @timeout 15000
      {fetchMines} = new Registry

      it 'should reject all values except dev, prod or all in type of mine', (done) ->
        (shouldBeRejected fetchMines [], ['unexpect']) done
        return #To not return empty promise


      it 'should fetch all mines given nothing in the query parameter', ->
        (fetchMines [], []).then (mines) ->
          nock 'http://registry.intermine.org'
            .get '/service/'
            .reply 200, statusCode: 201, instances: {}
          should.exist mines
          mines.should.have.properties statusCode: 200
          mines.should.have.property 'instances'

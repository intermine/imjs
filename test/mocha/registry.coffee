should = require 'should'
{prepare, eventually} = require './lib/utils'

Fixture = require './lib/fixture'

{Registry} = Fixture

describe 'Registry', ->

  describe 'new Registry', ->

    it 'should make a new registry adapter', ->
      registry = new Registry
      should.exist registry
      registry.should.be.an.instanceOf Registry

    describe 'getFormat', ->

      it 'should return format of query and default back to json', ->
        {getFormat} = new Registry
        getFormat().should.equal 'json'
        getFormat('xml').should.equal 'xml'

    describe 'makePath', ->

      it 'should return complete path, assembling root url and query parameters', ->
        {makePath} = new Registry
        # Get the root of the registry passing in nothing
        root = makePath '', {}
        root.should.equal 'http://registry.intermine.org/service/'
        (makePath 'outer/inner', {}).should.equal "#{root}outer/inner"
        (makePath 'outer/inner', {a: 2, b: 3}).should.equal "#{root}outer/inner?a=2&b=3"

    describe 'isEmpty', ->

      it 'should return true if an object is empty and has Object as prototype, false if not', ->
        {isEmpty} = new Registry
        (isEmpty {}).should.be.true
        (isEmpty {a: 1}).should.be.false

    describe 'fetchMines', ->

      # @beforeAll prepare -> new Registry().fetchMines()
      @timeout 15000

      it 'should fetch all mines given nothing in the query parameter', ->
        {fetchMines} = new Registry
        (fetchMines [], []).then (mines) ->
          # console.log 'hello world'
          # console.log err
          # console.log mines
          should.not.exist err
          # should.exist err
          mines.should.be.an 'object'
        
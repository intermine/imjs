should = require 'should'

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
        (makePath 'outer/inner', {}).should.equal "#{root}outer/inner"

    describe 'isEmpty', ->

      it 'should return true if an object is empty and has Object as prototype, false if not', ->
        {isEmpty} = new Registry
        (isEmpty {}).should.equal true
        (isEmpty {a: 1}).should.equal false
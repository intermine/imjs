should = require 'should'

{Registry} = require './lib/fixture'

describe 'Registry', ->

  describe 'new Registry', ->

    it 'should make a new registry adapter', ->
      registry = new Registry
      should.exist registry
      registry.should.be.an.instanceOf Registry

    describe 'getFormat', ->

      it 'should return format of query and default back to json', ->
        {getFormat} = new Registry
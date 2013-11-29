{prepare, eventually, always, clear} = require './lib/utils'
should = require 'should'
Fixture = require './lib/fixture'
{success, sequence, curry, invoke} = Fixture.funcutils

describe 'List', ->

  {service} = new Fixture()
  remove = curry clear, service
  FAVS = 'My-Favourite-Employees'
  tags = ['temp', 'testing', 'node', 'mocha', 'rename']

  @slow 500

  describe '#rename(name)', ->

    name = 'temp-copy-of-favs-rename'
    newName = 'temp-renamed'
    cleanUp = -> sequence (remove name), (remove newName)
    @afterAll always cleanUp
    @beforeAll prepare -> cleanUp().then ->
      service.fetchList(FAVS).then(invoke 'copy', {tags, name})
           .then( (copy) -> copy.rename newName )

    it 'should exist', eventually (list) ->
      should.exist list
    
    it 'should be called ' + newName, eventually (list) ->
      list.name.should.equal newName

    it 'should have 4 members', eventually (list) ->
      list.size.should.equal 4

  describe '#rename(name, cb)', ->
    
    name = 'temp-copy-of-favs-rename-w-cb'
    newName = 'temp-renamed'
    cleanup = -> sequence (remove name), (remove newName)
    
    @beforeAll prepare cleanup
    @afterAll always cleanup

    it 'should support the callback API', (done) ->
      test = (copy) ->
        copy.rename newName, (err, renamed) ->
          return done err if err?
          try
            copy.name.should.equal newName
            copy.size.should.equal 4
            should.exist renamed
            renamed.name.should.equal newName
            renamed.size.should.equal 4
            done()
          catch e
            done e
      service.fetchList(FAVS).then(invoke 'copy', {tags, name}).done test, done


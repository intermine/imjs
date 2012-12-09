{prepare, eventually, always, clear} = require './lib/utils'
should = require 'should'
Fixture = require './lib/fixture'
{success} = Fixture.funcutils
once = require('underscore.deferred').when

describe 'List', ->

    {service} = new Fixture()

    describe '#rename(name)', ->

        name = 'temp-copy-of-favs-rename'
        newName = 'temp-renamed'
        tags = ['temp', 'testing', 'node', 'mocha', 'copy']
        wipers = [clear(service, name), clear(service, newName)]
        cleanUp = -> once( f() for f in wipers )
        @afterAll always cleanUp
        @beforeAll prepare -> cleanUp().then ->
            service.fetchList('My-Favourite-Employees')
                   .then( (list) -> list.copy {tags, name} )
                   .then( (copy) -> copy.rename newName )

        it 'should exist', eventually (list) ->
            should.exist list
        
        it 'should be called ' + newName, eventually (list) ->
            list.name.should.equal newName

        it 'should have 4 members', eventually (list) ->
            list.size.should.equal 4

    describe '#rename(name, cb)', ->
        
        name = 'temp-copy-of-favs-rename'
        newName = 'temp-renamed'
        
        it 'should exist', eventually (list) ->
            should.exist list
        
        it 'should be called ' + newName, eventually (list) ->
            list.name.should.equal newName

        it 'should have 4 members', eventually (list) ->
            list.size.should.equal 4

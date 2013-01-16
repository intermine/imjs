{prepare, eventually, always, clear} = require './lib/utils'
should = require 'should'
Fixture = require './lib/fixture'
{success} = Fixture.funcutils
once = require('underscore.deferred').when

describe 'List', ->

  {service} = new Fixture()

  @beforeAll always -> service.fetchLists().then (lists) ->
    once (l.del() for l in lists when l.name.match(/_copy/) or l.hasTag('copy'))

  @slow 400

  describe '#copy()', ->

    temp = null
    @beforeAll prepare -> temp = service.fetchList('My-Favourite-Employees').then (l) -> l.copy()
    @afterAll always -> if temp? then temp.then((l) -> l.del()) else success()

    it 'should produce a copy', eventually (copy) ->
      should.exist copy

    it 'should have the same number of members', eventually (copy) ->
      copy.size.should.equal 4

    it 'should have a different name', eventually (copy) ->
      copy.name.should.not.equal 'My-Favourite-Employees'

  describe '#copy({tags})', ->

    temp = null
    args = tags: ['temp', 'testing', 'node', 'mocha', 'copy']
    @beforeAll prepare -> temp = service.fetchList('My-Favourite-Employees').then (l) ->
      l.copy(args)
    @afterAll always -> if temp? then temp.then((l) -> l.del()) else success()

    it 'should produce a copy', eventually (copy) ->
      should.exist copy

    it 'should have the same number of members', eventually (copy) ->
      copy.size.should.equal 4

    it 'should have a different name', eventually (copy) ->
      copy.name.should.not.equal 'My-Favourite-Employees'
    
    it 'should have all the tags we added', eventually (copy) ->
      copy.hasTag(t).should.be.true for t in args.tags

  describe '#copy({name, tags})', ->

    args =
      name: 'temp-copy-of-favs'
      tags: ['temp', 'testing', 'node', 'mocha', 'copy']
    cleanUp = clear service, args.name
    @beforeAll prepare -> cleanUp().then -> service.fetchList('My-Favourite-Employees').then (l) ->
      l.copy args
    @afterAll always cleanUp

    it 'should produce a copy', eventually (copy) ->
      should.exist copy

    it 'should have the same number of members', eventually (copy) ->
      copy.size.should.equal 4

    it 'should have a different name', eventually (copy) ->
      copy.name.should.not.equal 'My-Favourite-Employees'
    
    it 'should have all the tags we added', eventually (copy) ->
      copy.hasTag(t).should.be.true for t in args.tags

    it 'should in fact have the name we gave it', eventually (copy) ->
      copy.name.should.equal args.name


  describe '#copy(name)', ->

    name = 'temp-copy-of-favs'
    cleanUp = clear service, name
    @beforeAll prepare -> cleanUp().then -> service.fetchList('My-Favourite-Employees').then (l) ->
      l.copy name
    @afterAll always cleanUp

    it 'should produce a copy', eventually (copy) ->
      should.exist copy

    it 'should have the same number of members', eventually (copy) ->
      copy.size.should.equal 4

    it 'should have a different name', eventually (copy) ->
      copy.name.should.not.equal 'My-Favourite-Employees'

    it 'should in fact have the name we gave it', eventually (copy) ->
      copy.name.should.equal name

  describe '#copy(name, cb)', ->

    name = 'temp-copy-of-favs-with-cb'

    cleanUp = clear service, name
    @beforeAll prepare cleanUp
    @afterAll always cleanUp

    it 'should make a list with the right name and size', (done) ->
      promise = @promise.then -> service.fetchList('My-Favourite-Employees').then (favs) ->
        favs.copy name, (copy) ->
          should.exist copy
          copy.size.should.equal 4
          copy.name.should.not.equal 'My-Favourite-Employees'
          copy.name.should.equal name
          done()

      promise.fail done

  describe '#copy({name, tags}, cb)', ->

    args =
      name: 'temp-copy-of-favs'
      tags: ['temp', 'testing', 'node', 'mocha', 'copy']
    cleanUp = clear service, args.name
    @beforeAll prepare cleanUp
    @afterAll always cleanUp

    it 'should make a list with the right name and size', (done) ->
      promise = @promise.then -> service.fetchList('My-Favourite-Employees').then (favs) ->
        favs.copy args, (copy) ->
          should.exist copy
          copy.size.should.equal 4
          copy.name.should.not.equal 'My-Favourite-Employees'
          copy.name.should.equal args.name
          copy.hasTag(t).should.be.true for t in args.tags
          done()

      promise.fail done

  describe '#copy(cb)', ->

    promise = null
    @afterAll always -> if promise? then promise.then((l) -> l.del()) else success()

    it 'should make a list with the right name and size', (done) ->
      promise = @promise.then -> service.fetchList('My-Favourite-Employees').then (favs) ->
        favs.copy (copy) ->
          should.exist copy
          copy.size.should.equal 4
          copy.name.should.not.equal 'My-Favourite-Employees'
          done()

      promise.fail done



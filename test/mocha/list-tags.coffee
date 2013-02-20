{always, prepare, eventually} = require './lib/utils'
should = require 'should'
Fixture = require './lib/fixture'

describe 'List', ->

  {service} = new Fixture()

  origList = 'My-Favourite-Employees'

  describe '#fetchTags()', ->

    @beforeAll prepare -> service.fetchList(origList).then (l) -> l.fetchTags()

    it 'should start by finding no tags', eventually (tags) ->
      tags.length.should.equal 0

  describe '#addTags(tags)', ->

    tags = ['test', 'mocha', 'addTags']
    list = null

    @beforeAll prepare -> service.fetchList(origList).then (l) ->
      list = l
      l.addTags(tags)
    @afterAll always -> service.fetchList(origList).then (l) -> l.removeTags(tags)

    it 'should yield three tags', eventually (ret) ->
      ret.length.should.equal 3

    it 'should yield the tags themselves', eventually (ret) ->
      ret.should.include 'test'

    it 'should have updated the list itself', eventually (ret) ->
      list.tags.should.eql ret

  describe '#fetchTags() after update', ->

    tags = ['test', 'mocha', 'addTags']
    list = null

    @beforeAll prepare -> service.fetchList(origList).then (l) ->
      list = l
      l.addTags(tags).then -> l.fetchTags()
    @afterAll always -> service.fetchList(origList).then (l) -> l.removeTags(tags)

    it 'should yield three tags', eventually (ret) ->
      ret.length.should.equal 3

    it 'should yield the tags themselves', eventually (ret) ->
      ret.should.include 'test'
  
    it 'should have updated the list itself', eventually (ret) ->
      list.tags.should.eql ret

  describe '#removeTags(tags)', ->

    tags = ['test', 'mocha', 'removeTags', 'toRemove']

    @beforeAll prepare -> service.fetchList(origList).then (l) ->
      l.addTags(tags).then -> l.removeTags('toRemove')
    @afterAll always -> service.fetchList(origList).then (l) -> l.removeTags(tags)

    it 'should yield three tags', eventually (ret) ->
      ret.length.should.equal 3

    it 'should yield the tags themselves', eventually (ret) ->
      ret.should.include 'test'
      ret.should.include 'removeTags'

    it 'should no longer include the removed tag', eventually (ret) ->
      ret.should.not.include 'toRemove'

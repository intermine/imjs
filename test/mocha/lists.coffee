{prepare, eventually} = require './lib/utils'
should = require 'should'
Fixture = require './lib/fixture'

describe 'Service', ->

  {service} = new Fixture()

  describe '#fetchLists()', ->

    @beforeAll prepare -> service.fetchLists()

    it 'should find at least one list', eventually (lists) ->
      lists.length.should.be.above 0

    it 'should contain "My-Favourite-Employees"', eventually (lists) ->
      (l.name for l in lists).should.include 'My-Favourite-Employees'


  describe '#fetchLists (lists) ->', ->

    it 'should find "My-Favourite-Employees"', (done) ->
      promise = service.fetchLists (lists) ->
        (l.name for l in lists).should.include 'My-Favourite-Employees'
        done()
      promise.then null, done

  describe '#fetchList()', ->

    @beforeAll prepare -> service.fetchList 'My-Favourite-Employees'

    it 'should find that list', eventually (list) ->
      should.exist list

    it 'should find the right list', eventually (list) ->
      list.name.should.equal 'My-Favourite-Employees'

    it 'should have 4 members', eventually (list) ->
      list.size.should.equal 4

    it 'should contain David', eventually (list) ->
      list.contents().then (members) ->
        (m.name for m in members).should.include 'David Brent'

  describe '#fetchList (list) ->', ->

    it 'should find "My-Favourite-Employees"', (done) ->
      promise = service.fetchList 'My-Favourite-Employees', (list) ->
        should.exist list
        list.name.should.equal 'My-Favourite-Employees'
        list.size.should.equal 4
        done()

      promise.then null, done


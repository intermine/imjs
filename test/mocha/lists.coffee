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
      (l.name for l in lists).should.containEql 'My-Favourite-Employees'


  describe '#fetchLists (err, list) ->', ->

    it 'should find "My-Favourite-Employees"', (done) ->
      service.fetchLists (err, lists) ->
        return done err if err?
        try
          (l.name for l in lists).should.containEql 'My-Favourite-Employees'
          done()
        catch e
          done e
      return undefined

  describe '#findLists name', ->

    @beforeAll prepare -> service.findLists 'My-Favourite-Employees'

    it 'should find one list', eventually (lists) ->
      lists.length.should.equal 1

    it 'should find the right list', (done) ->
      test = ([list]) ->
        list.name.should.equal 'My-Favourite-Employees'
      promise = service.findLists 'My-Favourite-Employees'
      promise.then ((lists) ->
        test lists
        done()
      )
      return undefined

    it 'should have 4 members', eventually ([list]) ->
      list.size.should.equal 4

  describe '#findLists name, (err, lists) ->', ->

    it 'should find the right list', (done) ->

      service.findLists 'My-Favourite-Employees', (err, lists) ->
        #return done err if err?
        if err?
          done err
        else
          try
            lists.length.should.equal 1
            lists[0].size.should.equal 4
            done()
          catch e
            done e
      return undefined

  describe '#fetchList()', ->

    @beforeAll prepare -> service.fetchList 'My-Favourite-Employees'

    it 'should find that list', (done) ->
      test = (list) ->
        should.exist list
      promise = service.fetchList 'My-Favourite-Employees'
      promise.then ((list) ->
        test list
        done()
      )
      return undefined

    it 'should find the right list', (done) ->
      test =  (list) ->
        list.name.should.equal 'My-Favourite-Employees'
      promise = service.fetchList 'My-Favourite-Employees'
      promise.then ((list) ->
        test list
        done()
      )
      return undefined

    it 'should have 4 members', eventually (list) ->
      list.size.should.equal 4

    it 'should contain David', eventually (list) ->
      list.contents().then (members) ->
        (m.name for m in members).should.containEql 'David Brent'

  describe '#fetchList (err, list) ->', ->

    it 'should find "My-Favourite-Employees"', (done) ->
      service.fetchList 'My-Favourite-Employees', (err, list) ->
        done err if err?
        try
          should.exist list
          list.name.should.equal 'My-Favourite-Employees'
          list.size.should.equal 4
          done()
        catch e
          done e
      return undefined

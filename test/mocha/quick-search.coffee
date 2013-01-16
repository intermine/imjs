Fixture = require './lib/fixture'
{report, eventually} = require './lib/utils'

describe 'Service#search', ->

  {service} = new Fixture()

  describe 'using the promise API', ->
  
    describe 'to look for everything', ->

      @beforeAll (done) -> report done, @promise = service.search()

      it 'should find at least 100 things', eventually (rs) ->
        rs.length.should.be.above 99

      it 'should find some banks', eventually (_, facets) ->
        facets.Category.Bank.should.equal 5

    describe 'to look for David', ->

      @beforeAll (done) -> report done, @promise = service.search 'david'

      it 'should find david and his department', eventually (rs) ->
        rs.length.should.equal 2

      it 'should find one department', eventually (_, facets) ->
        facets.Category.Department.should.equal 1

      it 'should find one manager', eventually (_, facets) ->
        facets.Category.Manager.should.equal 1

    describe 'to look for David, with a request object', ->

      @beforeAll (done) -> report done, @promise = service.search q: 'david'

      it 'should find david and his department', eventually (rs) ->
        rs.length.should.equal 2

      it 'should find one department', eventually (_, facets) ->
        facets.Category.Department.should.equal 1

      it 'should find one manager', eventually (_, facets) ->
        facets.Category.Manager.should.equal 1

    describe 'searcing by a specific type', ->

      @beforeAll (done) ->
        report done, @promise = service.search q: 'david', Category: 'Department'

      it.skip "should find david's department", eventually (rs) ->
        rs.length.should.equal 1.1

      it 'should find one department', eventually (_, facets) ->
        facets.Category.Department.should.equal 1

      it.skip 'should not find any departments', eventually (_, facets) ->
        should = require 'should'
        should.not.exist facets.Category.Manager


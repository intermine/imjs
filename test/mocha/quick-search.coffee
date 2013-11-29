Fixture = require './lib/fixture'
{prepare, report, eventually} = require './lib/utils'

describe 'Service#search', ->

  {service} = new Fixture()

  describe 'using the promise API', ->
  
    describe 'to look for everything', ->

      @beforeAll prepare -> service.search()

      it 'should find at least 100 things', eventually ({results}) ->
        results.length.should.be.above 99

      it 'should find some banks', eventually ({facets}) ->
        facets.Category.Bank.should.equal 5

    describe 'to look for David', ->

      @beforeAll prepare -> service.search 'david'

      it 'should find david and his department', eventually ({results}) ->
        results.length.should.equal 2

      it 'should find one department', eventually ({facets}) ->
        facets.Category.Department.should.equal 1

      it 'should find one manager', eventually ({facets}) ->
        facets.Category.Manager.should.equal 1

    describe 'to look for David, with a request object', ->

      @beforeAll prepare -> service.search q: 'david'

      it 'should find david and his department', eventually ({results}) ->
        results.length.should.equal 2

      it 'should find one department', eventually ({facets}) ->
        facets.Category.Department.should.equal 1

      it 'should find one manager', eventually ({facets}) ->
        facets.Category.Manager.should.equal 1

    describe 'searcing by a specific type', ->

      @beforeAll prepare -> service.search q: 'david', Category: 'Department'

      it "should find david's department", eventually ({results}) ->
        results.length.should.equal 1

      it 'should find one department', eventually ({facets}) ->
        facets.Category.Department.should.equal 1

      it 'should not find any managers', eventually ({facets}) ->
        should = require 'should'
        should.not.exist facets.Category.Manager


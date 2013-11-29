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

  describe 'using the callback API', ->
  
    describe 'to look for everything', ->

      it 'should find at least 100 things, and some banks', (done) ->
        service.search (err, resp) ->
          return done err if err?
          try
            resp.results.length.should.be.above 99
            resp.facets.Category.Bank.should.equal 5
            done()
          catch e
            done e

    describe 'to look for David', ->

      it 'should find david and his department', (done) ->
        service.search 'david', (err, {results, facets} = {}) ->
          return done err if err?
          try
            results.length.should.equal 2
            facets.Category.Department.should.equal 1
            facets.Category.Manager.should.equal 1
            done()
          catch e
            done e

    describe 'searching by a specific type', ->

      it "should find david's department, and no managers", (done) ->
        service.search {q: 'david', Category: 'Department'}, (err, {results, facets} = {}) ->
          return done err if err?
          try
            results.length.should.equal 1
            facets.Category.Department.should.equal 1
            should = require 'should'
            should.not.exist facets.Category.Manager
            done()
          catch e
            done e

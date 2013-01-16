Fixture = require './lib/fixture'
{report, eventually} = require './lib/utils'
{get} = Fixture.funcutils

describe 'Service#fetchListsContaining', ->

  {service} = new Fixture()

  describe 'searching for public ids', ->

    @beforeAll (done) ->
      @promise = service.fetchListsContaining
        type: 'Employee'
        publicId: 'Brenda'
      @promise.fail(done).done -> done()

    it 'should find the right number of lists', eventually (ls) ->
      ls.length.should.equal 2

    it 'should find "the great unknowns"', eventually (ls) ->
      (l.name for l in ls).should.include 'The great unknowns'

  describe 'searching for internal ids', ->

    @beforeAll (done) ->
      q = select: ['Employee.id'], where: {name: 'David Brent'}
      report done, @promise = service.rows(q)
        .then(get 0).then(get 0)
        .then (id) -> service.fetchListsContaining {id}

    it 'should find the right number of lists', eventually (ls) ->
      ls.length.should.equal 3

    it 'should find "My-Favourite-Employees"', eventually (ls) ->
      (l.name for l in ls).should.include 'My-Favourite-Employees'



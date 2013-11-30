Fixture = require './lib/fixture'
{prepare, report, eventually, cleanSlate} = require './lib/utils'
{get} = Fixture.funcutils

describe 'Service#fetchListsContaining', ->

  {service} = new Fixture()

  @beforeAll cleanSlate service

  describe 'searching for public ids', ->

    @beforeAll prepare -> service.fetchListsContaining
      type: 'Employee'
      publicId: 'Brenda'

    it 'should find the right number of lists', eventually (ls) ->
      ls.length.should.equal 2

    it 'should find "the great unknowns"', eventually (ls) ->
      (l.name for l in ls).should.include 'The great unknowns'

  describe 'searching with the callback api', ->

    it 'should still work', (done) ->
      options =
        type: 'Employee'
        publicId: 'Brenda'
      service.fetchListsContaining options, (err, lists) ->
        return done err if err?
        try
          lists.length.should.equal 2
          (l.name for l in lists).should.include 'The great unknowns'
          done()
        catch e
          done e

  describe 'searching for internal ids', ->

    @beforeAll prepare ->
      q = select: ['Employee.id'], where: {name: 'David Brent'}
      service.values(q)
             .then(get 0)
             .then (id) -> service.fetchListsContaining {id}

    it 'should find the right number of lists', eventually (ls) ->
      ls.length.should.equal 3

    it 'should find "My-Favourite-Employees"', eventually (ls) ->
      (l.name for l in ls).should.include 'My-Favourite-Employees'



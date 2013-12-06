Fixture                      = require './lib/fixture'
{eventually, prepare, parallel} = require './lib/utils'

describe 'Query', ->

  describe 'with-subclasses', ->
    {service} = new Fixture

    describe 'running a subclass query', ->

      @beforeAll prepare -> service.count
        from: 'Department',
        select: ['employees.name'],
        where: {'employees': {isa: 'CEO'}}
      
      it 'should find six ceos who work in departments', eventually (c) ->
        c.should.equal 6

    describe 'running a multi-type query', ->

      ceos =
        from: 'CEO'
        select: ['name']
      contractors =
        from: 'Contractor'
        select: ['name']
      union =
        from: 'Employable'
        select: ['name']
        where: {'Employable': { isa: ['Contractor', 'CEO'] }}

      @beforeAll prepare -> parallel (service.count q for q in [ceos, contractors, union])

      it 'ceos + contractors should = union', eventually ([a, b, c]) ->
        (a + b).should.equal c

      it 'should find 15 contractors or ceos', eventually ([a, b, c]) ->
        c.should.equal 15


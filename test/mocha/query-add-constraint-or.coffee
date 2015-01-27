{Query, Model} = Fixture = require './lib/fixture'
{eventually, prepare} = require './lib/utils'
{TESTMODEL} = require '../data/model'

describe 'Query#addConstraint', ->

  describe 'one existing constraint', ->
    q = null
    
    @beforeEach ->
      q = new Query
        model: new Model TESTMODEL.model
        root: 'Employee'
        select: ['name', 'department.manager.company.name']
        where: [['age', '>', 30]]
      q.addConstraint ['age', '<', 60], 'or'

    it 'should be able to add constraints with "or"', ->
      q.constraints.length.should.eql 2

    it 'should set the logic to use "or"', ->
      q.constraintLogic.should.eql "A or B"

  describe 'multiple existing constraints', ->
    q = null
    
    @beforeEach ->
      q = new Query
        model: new Model TESTMODEL.model
        root: 'Employee'
        select: ['name', 'department.manager.company.name']
        where: [['department.name', '=', 'Sales'], ['age', '>', 30]]
      q.addConstraint ['age', '<', 60], 'or'

    it 'should be able to add constraints with "or"', ->
      q.constraints.length.should.eql 3

    it 'should set the logic to use "or"', ->
      q.constraintLogic.should.eql "(A and B) or C"


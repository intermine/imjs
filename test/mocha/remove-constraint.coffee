Fixture = require './lib/fixture'
{eventually, prepare} = require './lib/utils'
{defer} = Fixture.utils

constraints = [
  {path: 'Employee.department.manager', type: 'CEO'},
  {path: 'Employee.name', op: '=', value: 'methuselah'},
  {path: 'Employee.age', op: '>', value: 1000},
  {path: 'Employee.end', op: 'IS NULL'},
  {path: 'Employee.department.name', op: 'ONE OF', values: ['Sales', 'Accounting']}
]

describe 'Query', ->

  {service} = new Fixture

  @beforeEach prepare -> service.query select: ['name'], from: 'Employee', where: constraints

  describe '#removeConstraint(con)', ->

    it 'should be able to remove a constraint', eventually (q) ->
      changes = 0
      q.on 'change:constraints', -> changes++
      n = constraints.length
      q.constraints.length.should.equal n
      for x in constraints
        q.removeConstraint x
        q.constraints.length.should.equal --n
      changes.should.equal constraints.length

  describe 'removed:constraint event', ->

    it 'should be triggered when constraints are removed', eventually (q) ->
      {promise, resolve, reject} = defer()
      q.on 'removed:constraint', (c) ->
        try
          resolve c.should.eql constraints[1]
        catch e
          reject()
      q.removeConstraint constraints[1]
      reject "Event not fired"
      return promise


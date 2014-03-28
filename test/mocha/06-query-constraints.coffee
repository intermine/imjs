{Query} = Fixture = require './lib/fixture'
{eventually, prepare} = require './lib/utils'

expected = [
  {path: 'Employee.department.manager', type: 'CEO'},
  {path: 'Employee.name', op: '=', value: 'methuselah'},
  {path: 'Employee.age', op: '>', value: 1000},
  {path: 'Employee.end', op: 'IS NULL'},
  {path: 'Employee.department.name', op: 'ONE OF', values: ['Sales', 'Accounting']},
  {path: 'Employee.address', op: 'LOOKUP', value: 'Springfield', extraValue: 'Illinois'}
]

someSwitchedOff = [
  {path: 'Employee.department.manager', type: 'CEO'},
  {path: 'Employee.name', op: '=', value: 'methuselah'},
  {path: 'Employee.age', op: '>', value: 1000},
  {path: 'Employee.company', op: 'LOOKUP', value: 'W*', switchable: true, switched: 'OFF'}
  {path: 'Employee.end', op: 'IS NULL'},
  {path: 'Employee.department.name', op: 'ONE OF', values: ['Sales', 'Accounting']},
  {path: 'Employee.address', op: 'LOOKUP', value: 'Springfield', extraValue: 'Illinois'},
  {path: 'Employee.department.name', op: '=', value: 'Sales', switchable: true, switched: 'OFF'}
]

headless = [
  {path: 'department.manager', type: 'CEO'},
  {path: 'name', op: '=', value: 'methuselah'},
  {path: 'age', op: '>', value: 1000},
  {path: 'end', op: 'IS NULL'},
  {path: 'department.name', op: 'ONE OF', values: ['Sales', 'Accounting']},
  {path: 'address', op: 'LOOKUP', value: 'Springfield', extraValue: 'Illinois'}
]

arrays = [
  ['department.manager', 'CEO'],
  ['name', '=', 'methuselah'],
  ['age', '>', 1000],
  ['end', 'IS NULL'],
  ['department.name', 'ONE OF', ['Sales', 'Accounting']],
  ['address', 'LOOKUP', 'Springfield', 'Illinois']
]

operatorAliases = [
  ['department.manager', 'CEO'],
  ['name', 'eq', 'methuselah'],
  ['age', 'gt', 1000],
  ['end', 'is null'],
  ['department.name', 'one of', ['Sales', 'Accounting']],
  ['address', 'lookup', 'Springfield', 'Illinois']
]

mapping =
  'department.manager': {isa: 'CEO'}
  name: 'methuselah'
  age: {gt: 1000}
  end: 'is null'
  'department.name': ['Sales', 'Accounting']
  address: {lookup: 'Springfield', extraValue: 'Illinois'}

mappingWithNull =
  'department.manager': {isa: 'CEO'}
  name: 'methuselah'
  age: {gt: 1000}
  end: null
  'department.name': ['Sales', 'Accounting']
  address: {lookup: 'Springfield', extraValue: 'Illinois'}

constraintsTest = (input) -> () ->

  it 'should work using the constraints key', ->
    q = new Query root: 'Employee', constraints: input
    q.constraints.should.eql expected

  it 'should work using the where key', ->
    q = new Query from: 'Employee', where: input
    q.constraints.should.eql expected

  it 'should be able to add them one by one using #addConstraint', ->
    q = new Query root: 'Employee'
    if input.length?
      q.addConstraint c for c in input
      q.constraints.should.eql expected
    else
      # Not relevant - only here for testing arrays.
      true.should.equal.true

  it 'should be able to add them all at once using #addConstraints', ->
    q = new Query root: 'Employee'
    q.addConstraints input
    q.constraints.should.eql expected

describe 'Defining Query constraints', ->

  describe 'using the internal verbose format', constraintsTest expected

  describe 'using headless paths', constraintsTest headless

  describe 'using array encoding', constraintsTest arrays

  describe 'using operator aliases', constraintsTest operatorAliases

  describe 'using an mapping', constraintsTest mapping

  describe 'using a null value', constraintsTest mappingWithNull

  describe 'including switched off constraints', constraintsTest someSwitchedOff

describe 'Query', ->

  describe '#isConstrained', ->

    {service} = new Fixture()

    @beforeAll prepare -> service.query
      from: 'Employee'
      select: 'name'
      where:
        age: 10
        'department.manager': { isa: 'CEO' }
        'address.address': 'IS NOT NULL'
        'department.company': {lookup: '*Hogg'}

    it 'should say that "Employee.age" is constrained', eventually (q) ->
      q.isConstrained('Employee.age').should.be.true

    it 'should say that "Employee.department.company" is constrained', eventually (q) ->
      q.isConstrained('Employee.department.company').should.be.true

    it 'should say that "Employee.address.address" is constrained', eventually (q) ->
      q.isConstrained('Employee.address.address').should.be.true

    it 'should not say that "Employee.address" is constrained', eventually (q) ->
      q.isConstrained('Employee.address').should.not.be.true

    it 'should not say that "Employee.department.manager" is constrained', eventually (q) ->
      q.isConstrained('Employee.department.manager').should.not.be.true

    it 'should not say that "Employee.department.company.name" is constrained', eventually (q) ->
      q.isConstrained('Employee.department.company.name').should.not.be.true

    it 'should not say that "departmentThatRejectedMe.name" is constrained', eventually (q) ->
      q.isConstrained('Employee.departmentThatRejectedMe.name').should.not.be.true

    it 'should say that and attr of "Employee.address" is constrained', eventually (q) ->
      q.isConstrained('Employee.address', true).should.be.true


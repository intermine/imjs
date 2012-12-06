{Query} = require './lib/fixture'

expected = [
    {path: 'Employee.department.manager', type: 'CEO'},
    {path: 'Employee.name', op: '=', value: 'methuselah'},
    {path: 'Employee.age', op: '>', value: 1000},
    {path: 'Employee.end', op: 'IS NULL'},
    {path: 'Employee.department.name', op: 'ONE OF', values: ['Sales', 'Accounting']}
]

headless = [
    {path: 'department.manager', type: 'CEO'},
    {path: 'name', op: '=', value: 'methuselah'},
    {path: 'age', op: '>', value: 1000},
    {path: 'end', op: 'IS NULL'},
    {path: 'department.name', op: 'ONE OF', values: ['Sales', 'Accounting']}
]

arrays = [
    ['department.manager', 'CEO'],
    ['name', '=', 'methuselah'],
    ['age', '>', 1000],
    ['end', 'IS NULL'],
    ['department.name', 'ONE OF', ['Sales', 'Accounting']]
]

operatorAliases = [
    ['department.manager', 'CEO'],
    ['name', 'eq', 'methuselah'],
    ['age', 'gt', 1000],
    ['end', 'is null'],
    ['department.name', 'one of', ['Sales', 'Accounting']]
]

mapping =
    'department.manager': {isa: 'CEO'}
    name: 'methuselah'
    age: {gt: 1000}
    end: 'is null'
    'department.name': ['Sales', 'Accounting']

mappingWithNull =
    'department.manager': {isa: 'CEO'}
    name: 'methuselah'
    age: {gt: 1000}
    end: null
    'department.name': ['Sales', 'Accounting']

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

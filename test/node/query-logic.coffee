{Query} = require '../../src/query'

query =
    from: 'Employee',
    select: ['name'],
    where: {name: "david", age: 42, end: null},
    constraintLogic: "A or B and C"

exports['test default logic'] = (beforeExit, assert) ->
    q = new Query()
    assert.equal q.constraintLogic, ''

exports['test custom logic'] = (beforeExit, assert) ->
    q = new Query query
    assert.equal q.constraintLogic, 'A or B and C'

exports['alter custom logic'] = (beforeExit, assert) ->
    q = new Query query
    q.addConstraint path: 'fullTime', op: '=', value: "true"
    assert.equal q.constraintLogic, '(A or B and C) and D'

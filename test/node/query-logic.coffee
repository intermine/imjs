{Query} = require '../../src/query'

exports['test default logic'] = (beforeExit, assert) ->
    q = new Query()
    assert.equal q.constraintLogic, ''

exports['test custom logic'] = (beforeExit, assert) ->
    q = new Query from: 'Employee', select: ['name'], where: {name: "david", age: 42, end: null}, constraintLogic: "A or B and C"
    assert.equal q.constraintLogic, 'A or B and C'

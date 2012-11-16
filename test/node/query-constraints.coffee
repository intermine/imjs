{Query} = require '../../src/query'
{omap, fold}  = require '../../src/util'
{decap, lc} = require './lib/util'

expected = [
    {path: 'Employee.department.manager', type: 'CEO'},
    {path: 'Employee.name', op: '=', value: 'methuselah'},
    {path: 'Employee.age', op: '>', value: 1000},
    {path: 'Employee.end', op: 'IS NOT NULL'},
    {path: 'Employee.department.name', op: 'ONE OF', values: ['Sales', 'Accounting']}
]

exports['test Query.constraints: none'] = (beforeExit, assert) ->
    q = new Query root: 'Employee', constraints: expected
    assert.deepEqual q.constraints, expected

    q = new Query root: 'Employee', where: expected
    assert.deepEqual q.constraints, expected

exports['test Query.constraints: headless'] = (beforeExit, assert) ->
    headless = expected.map omap (k, v) -> [k, decap(v) ? v]

    q = new Query root: 'Employee', constraints: headless
    assert.deepEqual q.constraints,  expected

    q = new Query root: 'Employee', where: headless
    assert.deepEqual q.constraints,  expected

exports['test Query.constraints: just vals'] = (beforeExit, assert) ->
    justVals = expected.map fold([], (a, k, v) -> a.concat([v]))

    q = new Query root: 'Employee', constraints: justVals
    assert.deepEqual q.constraints,  expected

    q = new Query root: 'Employee', where: justVals
    assert.deepEqual q.constraints,  expected

exports['test Query.constraints: lc ops'] = (beforeExit, assert) ->
    lcOps = expected.map omap (k, v) -> [k, (if k is 'op' then lc(v) else v)]

    q = new Query root: 'Employee', constraints: lcOps
    assert.deepEqual q.constraints,  expected

    q = new Query root: 'Employee', where: lcOps
    assert.deepEqual q.constraints,  expected

exports['test Query.constraints: as object'] = (beforeExit, assert) ->
    conObj =
        "department.manager": {isa: 'CEO'}
        name: 'methuselah'
        age: {gt: 1000}
        end: 'is not null'
        'department.name': ['Sales', 'Accounting']

    q = new Query root: 'Employee', where: conObj
    assert.deepEqual q.constraints,  expected

exports['use null in null constraint'] = (beforeExit, assert) ->
    q = new Query from: 'Employee', where: {end: null}
    assert.deepEqual q.constraints, [{path: 'Employee.end', op: 'IS NULL'}]
    

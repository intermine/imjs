{asyncTest, older_emps} = require './lib/service-setup'
{get, invoke} = require '../../src/util'

davidQ = select: ['id'], from: 'Employee', where: {name: 'David Brent'}
b1q = select: ['id'], from: 'Employee', where: {name: 'EmployeeB1'}

exports['can find by id'] = asyncTest 5, (beforeExit, assert) ->
    s = @service
    s.query davidQ, (q) => q.rows (rows) => s.findById 'Employee', rows[0][0], (david) =>
        @runTest -> assert.equal 'David Brent', david.name
        @runTest -> assert.equal 'Sales', david.department.name
        @runTest -> assert.equal 41, david.age
        @runTest -> assert.equal false, david.fullTime
        @runTest -> assert.equal 'Manager', david['class']

exports['can find by id - promises'] = asyncTest 5, (beforeExit, assert) ->
    @service.query(davidQ).then(invoke 'rows').then(get 0).then(get 0)
        .then((id) => @service.findById('Employee', id))
        .then (david) =>
            @runTest -> assert.equal 'David Brent', david.name
            @runTest -> assert.equal 'Sales', david.department.name
            @runTest -> assert.equal 41, david.age
            @runTest -> assert.equal false, david.fullTime
            @runTest -> assert.equal 'Manager', david['class']

exports['can find by id - emp B1'] = asyncTest 5, (beforeExit, assert) ->
    s = @service
    s.query b1q, (q) => q.rows (rows) => s.findById 'Employee', rows[0][0], (empB1) =>
        @runTest -> assert.equal 'EmployeeB1', empB1.name
        @runTest -> assert.equal 'DepartmentB1', empB1.department.name
        @runTest -> assert.equal 40, empB1.age
        @runTest -> assert.equal true, empB1.fullTime
        @runTest -> assert.equal 'CEO', empB1['class']


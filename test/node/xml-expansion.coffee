{older_emps, asyncTest} = require './lib/service-setup'

expected_views = [
    'Employee.name',
    'Employee.department.name',
    'Employee.department.manager.name',
    'Employee.department.company.name',
    'Employee.fullTime',
    'Employee.address.address'
]

exports['view expansion'] = asyncTest 2, (beforeExit, assert) ->
    @service.query older_emps, (q) =>
        @runTest () -> assert.eql q.views, expected_views
        @runTest () -> assert.eql q.constraints, [{path: 'Employee.age', op: '>', value: 50}]

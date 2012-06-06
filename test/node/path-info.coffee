{asyncTest, older_emps} = require './lib/service-setup'

piTest = (f) -> asyncTest 1, (beforeExit, assert) ->
    @service.fetchModel (m) => @runTest f assert, m

piTypeTest = (path, type, subclasses) -> piTest (assert, m) -> () ->
    assert.eql type, m.getPathInfo(path, subclasses).getType()

exports['simple attribute'] = piTypeTest 'Employee.age', 'int'

exports['path with reference'] = piTypeTest 'Department.employees.name', 'String'

exports['path with subclassing'] = piTypeTest 'Department.employees.seniority', 'Integer', {'Department.employees': 'Manager'}
    
exports['long subclassed path'] = piTypeTest 'Department.employees.company.vatNumber', 'int', {'Department.employees': 'CEO'}

{asyncTest, older_emps} = require './lib/service-setup'

piTest = (f) -> asyncTest 1, (beforeExit, assert) ->
    @service.fetchModel (m) => @runTest f assert, m

piTypeTest = (path, type, subclasses) -> piTest (assert, m) -> () ->
    assert.eql type, m.getPathInfo(path, subclasses).getType()

exports['simple attribute'] = piTypeTest 'Employee.age', 'int'

exports['path with reference'] = piTypeTest 'Department.employees.name', 'String'

exports['path with subclassing'] = piTypeTest 'Department.employees.seniority', 'Integer', {'Department.employees': 'Manager'}
    
exports['long subclassed path'] = piTypeTest 'Department.employees.company.vatNumber', 'int', {'Department.employees': 'CEO'}

exports['path to string'] = asyncTest 4, (beforeExit, assert) ->
    path = 'Company.departments.employees.address.address'
    @service.fetchModel (m) =>
        @runTest () -> assert.eql path, m.getPathInfo(path).toString()
        @runTest () -> assert.eql path, m.getPathInfo(path).toPathString()
        @runTest () -> assert.eql path, "" + m.getPathInfo(path)
        @runTest () -> assert.equal path, "" + m.getPathInfo(path)

exports['path to string'] = asyncTest 16, (beforeExit, assert) ->
    attr = 'Company.departments.employees.address.address'
    ref = 'Company.departments.employees.address'
    coll = 'Company.departments.employees'
    root = 'Company'
    @service.fetchModel (m) =>
        @runTest () -> assert.ok m.getPathInfo(attr).isAttribute()
        @runTest () -> assert.ok !m.getPathInfo(attr).isReference()
        @runTest () -> assert.ok !m.getPathInfo(attr).isCollection()
        @runTest () -> assert.ok !m.getPathInfo(attr).isClass()

        @runTest () -> assert.ok !m.getPathInfo(ref).isAttribute()
        @runTest () -> assert.ok m.getPathInfo(ref).isReference()
        @runTest () -> assert.ok !m.getPathInfo(ref).isCollection()
        @runTest () -> assert.ok m.getPathInfo(ref).isClass()

        @runTest () -> assert.ok !m.getPathInfo(coll).isAttribute()
        @runTest () -> assert.ok m.getPathInfo(coll).isReference()
        @runTest () -> assert.ok m.getPathInfo(coll).isCollection()
        @runTest () -> assert.ok m.getPathInfo(coll).isClass()

        @runTest () -> assert.ok !m.getPathInfo(root).isAttribute()
        @runTest () -> assert.ok !m.getPathInfo(root).isReference()
        @runTest () -> assert.ok !m.getPathInfo(root).isCollection()
        @runTest () -> assert.ok m.getPathInfo(root).isClass()

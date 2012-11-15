{setup, asyncTest, older_emps} = require './lib/service-setup'
{LOG, ERR} = require './lib/util'
{invoke, id, NOT} = require '../../src/shiv'

piTest = (f) -> asyncTest 1, (beforeExit, assert) ->
    @service.fetchModel (m) => @runTest f assert, m

piTypeTest = (path, type, subclasses) -> piTest (assert, m) -> () ->
    assert.eql type, m.getPathInfo(path, subclasses).getType()

exports['simple attribute'] = piTypeTest 'Employee.age', 'int'

exports['path with reference'] = piTypeTest 'Department.employees.name', 'String'

exports['path with subclassing'] = piTypeTest 'Department.employees.seniority', 'Integer', {'Department.employees': 'Manager'}
    
exports['long subclassed path'] = piTypeTest 'Department.employees.company.vatNumber', 'int', {'Department.employees': 'CEO'}

parentTest = (path, expType, subclasses) -> piTest (assert, m) -> () ->
    assert.eql expType, m.getPathInfo(path, subclasses).getParent().getType().name

exports['type of parent'] = parentTest "Department.employees.name", "Employee", {}

exports['type of subclassed parent'] =
    parentTest "Department.employees.name", "Manager", {"Department.employees": "Manager"}

exports['path to string'] = asyncTest 3, (beforeExit, assert) ->
    path = 'Company.departments.employees.address.address'
    checker = (m) => @testCB (f) -> assert.eql path, f m.getPathInfo(path)
    @service.fetchModel().then(checker).then (check) ->
        check invoke 'toString'
        check invoke 'toPathString'
        check (x) -> '' + x

exports['PathInfo#containsCollection'] = asyncTest 6, (be, A) ->
    hasColls = [
        'Company.departments.employees.name',
        'Employee.department.employees.age',
        'Contractor.companys'
    ]
    doesnt = [
        'Employee.department.manager.address.address',
        'Company',
        'Employee.age'
    ]
    makePath = (str) => @service.fetchModel().then(invoke 'getPathInfo', str)
    test  = (f = id) => @testCB (p) -> A.ok f p.containsCollection()
    for hasgot in hasColls
        makePath(hasgot).done(test id)
    for hasnt in doesnt
        makePath(hasnt).done(test NOT)

exports['path types'] = asyncTest 16, (beforeExit, assert) ->
    attr = 'Company.departments.employees.address.address'
    ref = 'Company.departments.employees.address'
    coll = 'Company.departments.employees'
    root = 'Company'
    checker = (m) => @testCB (path, pred, f = id) -> assert.ok f m.getPathInfo(path)[pred]()

    @service.fetchModel().then(checker).then (check) ->
        check attr, 'isAttribute'
        check attr, 'isReference', NOT
        check attr, 'isCollection', NOT
        check attr, 'isClass', NOT

        check ref, 'isAttribute', NOT
        check ref, 'isReference'
        check ref, 'isCollection', NOT
        check ref, 'isClass'

        check coll, 'isAttribute', NOT
        check coll, 'isReference'
        check coll, 'isCollection'
        check coll, 'isClass'

        check root, 'isAttribute', NOT
        check root, 'isReference', NOT
        check root, 'isCollection', NOT
        check root, 'isClass'


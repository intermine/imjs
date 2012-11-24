{Service} = require '../../lib/service'
{test, asyncTest} = require './lib/service-setup'
{get} = require '../../src/util'

exports['test service root property'] = test (beforeExit, assert) ->
    assert.equal 'http://squirrel/intermine-test/service/', @service.root

exports['suitable roots are not altered'] = (beforeExit, assert) ->
    fmURI = 'http://www.flymine.org/query/service/'
    fm = new Service root: fmURI
    assert.equal fmURI, fm.root

exports['model'] = asyncTest 1, (beforeExit, assert) ->
    @service.fetchModel (m) => @runTest () -> assert.ok (v for _, v of m.classes).length > 0

exports['get templates - cb'] = asyncTest 1, (beforeExit, assert) ->
    @service.fetchTemplates @testCB (ts) -> assert.ok ts.ManagerLookup

exports['get templates - promise'] = asyncTest 1, (beforeExit, assert) ->
    @service.fetchTemplates().then(get 'ManagerLookup').done @testCB assert.ok

exports['summary fields'] = asyncTest 2, (beforeExit, assert) ->
    expected = [
        "Employee.name",
        "Employee.department.name",
        "Employee.department.manager.name",
        "Employee.department.company.name",
        "Employee.fullTime",
        "Employee.address.address"
    ]
    @service.fetchSummaryFields @testCB (sfs) -> assert.eql expected,  sfs.Employee
    @service.fetchSummaryFields().then(get 'Employee').done @testCB (got) -> assert.eql expected, got


{Service} = require '../../lib/service'
{test, asyncTest} = require './lib/service-setup'

exports['test service root property'] = test (beforeExit, assert) ->
    assert.equal 'http://squirrel/intermine-test/service/', @service.root

exports['suitable roots are not altered'] = (beforeExit, assert) ->
    fmURI = 'http://www.flymine.org/query/service/'
    fm = new Service root: fmURI
    assert.equal fmURI, fm.root

exports['version'] = asyncTest 1, (beforeExit, assert) ->
    @service.fetchVersion (v) => @runTest () -> assert.ok v > 0

exports['model'] = asyncTest 1, (beforeExit, assert) ->
    @service.fetchModel (m) => @runTest () -> assert.ok (v for _, v of m.classes).length > 0

exports['get templates'] = asyncTest 1, (beforeExit, assert) ->
    @service.fetchTemplates (ts) => @runTest () -> assert.includes (n for n, _ of ts), 'ManagerLookup'

exports['summary fields'] = asyncTest 1, (beforeExit, assert) ->
    expected = [
        "Employee.name",
        "Employee.department.name",
        "Employee.department.manager.name",
        "Employee.department.company.name",
        "Employee.fullTime",
        "Employee.address.address"
    ]
    @service.fetchSummaryFields (sfs) => @runTest () -> assert.eql sfs.Employee, expected

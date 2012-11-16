{asyncTest} = require './lib/service-setup'
{omap, fold}  = require '../../src/util'

query =
    from: 'Department'
    select: ['name', 'company.name', 'employees.name']
    where: {'employees.age': {lt: 26}}
    joins: ['company', 'employees']

expected = [
    [ 'Accounting', 'Wernham-Hogg', [] ],
    [ 'Accounting', 'Dunder-Mifflin', [] ],
    [ 'Accounting', 'Gogirep', [] ],
    [ 'Archiven', 'Capitol Versicherung AG', [] ],
    [ 'Board of Directors', 'Wernham-Hogg', [] ],
    [ 'Board of Directors', 'Capitol Versicherung AG', [] ],
    [ 'Board of Directors', 'Dunder-Mifflin', [] ],
    [ 'Board of Directors', 'Gogirep', [] ],
    [ 'Board of Directors', 'Difficulties Я Us', [] ],
    [ 'DepartmentA1', 'CompanyA', ['EmployeeA1', 'EmployeeA2'] ],
    [ 'DepartmentB1', 'CompanyB', [] ],
    [ 'DepartmentB2', 'CompanyB', [] ],
    [ 'Human Resources', 'Wernham-Hogg', [] ],
    [ 'Human Resources', 'Dunder-Mifflin', [] ],
    [ 'Human Resources', 'Gogirep', [] ],
    [ 'Kantine', 'Capitol Versicherung AG', [] ],
    [ 'Quotes', 'Difficulties Я Us', [] ],
    [ 'Sales', 'Wernham-Hogg', [] ],
    [ 'Sales', 'Dunder-Mifflin', [] ],
    [ 'Sales', 'Gogirep', [] ],
    [ 'Schadensregulierung', 'Capitol Versicherung AG', [] ],
    [ 'Schadensregulierung A-L', 'Capitol Versicherung AG', [] ],
    [ 'Schadensregulierung M-Z', 'Capitol Versicherung AG', [] ],
    [ 'Separators', 'Difficulties Я Us', [] ],
    [ 'Slashes', 'Difficulties Я Us', [] ],
    [ 'Verwaltung', 'Capitol Versicherung AG', [] ],
    [ 'Warehouse', 'Wernham-Hogg', [] ],
    [ 'Warehouse', 'Dunder-Mifflin', ['Madge Madsen'] ],
    [ 'Warehouse', 'Gogirep', [] ],
    [ 'XML Entities', 'Difficulties Я Us', [] ]
]

urk = -> console.error.apply console, arguments

exports['can fetch tablerows - piping'] = asyncTest 1, (beforeExit, assert) ->
    @service.query(query).pipe((q) -> q.tableRows()).fail(urk).done (rs) =>
        got = rs.map (r) -> [r[0].value, r[1].value, r[2].rows.map (sr) -> sr[0].value]
        @runTest () -> assert.eql got, expected

exports['can fetch tablerows'] = asyncTest 1, (beforeExit, assert) ->
    @service.query query, (q) => q.tableRows (rs) =>
        got = rs.map (r) -> [r[0].value, r[1].value, r[2].rows.map (sr) -> sr[0].value]
        @runTest () -> assert.eql got, expected


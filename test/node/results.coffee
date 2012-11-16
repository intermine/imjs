{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold, invoke}  = require '../../src/util'

expected = [
    "EmployeeB3",
    "Jennifer Taylor-Clarke",
    "Keith Bishop",
    "Trudy",
    "Rachel",
    "Carol",
    "Brenda",
    "Nathan",
    "Gareth Keenan",
    "Malcolm"
]

test = (tc, assert) -> (rs) -> tc.runTest -> assert.eql expected, (r.name for r in rs)

query = omap((k, v) -> [k, v]) older_emps
query.limit = 10 # Don't need them all...

exports['can fetch records - cb'] = asyncTest 1, (beforeExit, assert) ->
    @service.query query, (q) => q.records test @, assert

exports['can fetch records - promise'] = asyncTest 1, (beforeExit, assert) ->
    @service.query(query).pipe(invoke 'records').pipe(test @, assert).fail(@fail)

exports['can fetch records - then'] = asyncTest 1, (beforeExit, assert) ->
    @service.query(query).then(invoke 'records').then(test @, assert).fail(@fail)

exports['can iterate over records - promise'] = asyncTest expected.length, (beforeExit, assert) ->
    @service.query(query).then(invoke 'eachRecord').then invoke 'each', (record) =>
        @runTest -> assert.includes expected, record.name

exports['can iterate over records - cb'] = asyncTest expected.length, (beforeExit, assert) ->
    @service.query query, (q) => q.eachRecord (record) =>
        @runTest -> assert.includes expected, record.name


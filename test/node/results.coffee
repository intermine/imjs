{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold}  = require '../../src/shiv'

exports['can fetch records'] = asyncTest 1, (beforeExit, assert) ->
    query = omap((k, v) -> [k, v]) older_emps
    query.limit = 10 # Don't need them all...
    @service.query query, (q) => q.records (rs) =>
        names = rs.map (r) -> r.name
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
        @runTest () -> assert.eql names, expected


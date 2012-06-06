{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold}  = require '../../src/shiv'

exports['can page through requests'] = asyncTest 1, (beforeExit, assert) ->
    query = omap((k, v) -> [k, v]) older_emps
    query.limit = 10 # Don't need them all...
    expected =  [
            "Tatjana Berkel",
            "Jennifer Schirrmann",
            "Herr Fritsche",
            "Lars Lehnhoff",
            "Josef M\u00FCller",
            "Nyota N'ynagasongwa",
            "Herr Grahms",
            "Frank Montenbruck",
            "Andreas Hermann",
            "Jochen Sch\u00FCler"
    ]
    @service.query query, (q) => q.next().records (rs) => @runTest () ->
        assert.eql rs.map( (r) -> r.name ), expected

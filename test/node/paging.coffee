{asyncTest, older_emps} = require './lib/service-setup'
{invoke, copy, set, get}  = require '../../src/util'

query = (set {limit: 10}) copy older_emps
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
exports['can page through requests'] = asyncTest 1, (beforeExit, assert) ->
    @service.query(query)
        .then(invoke 'next')
        .then(invoke 'records')
        .then @testCB (rs) -> assert.eql expected, rs.map get 'name'

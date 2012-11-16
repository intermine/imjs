{asyncTest, older_emps} = require './lib/service-setup'
{get, invoke} = require '../../src/util'

# This query was failing in the webapp.
query =
    model: {"name":"testmodel"},
    select: ["Employee.name","Employee.age", "Employee.department.name"],
    where: [
        {
            path: "Employee.department.name",
            op: "NONE OF",
            code: "A",
            values:["Sales","Accounting"]
        }
    ]

exports['count is positive'] = asyncTest 1, (_, assert) ->
    @service.count(query).then @testCB (c) -> assert.ok c > 0, "#{ c } > 0"

exports['none of the results is in one of the banned departments'] = asyncTest 1, (_, assert) ->
    @service.rows(query)
            .then(invoke 'filter', (r) -> r[2] in query.where[0].values)
            .then(get 'length')
            .then @testCB (n) -> assert.eql 0, n


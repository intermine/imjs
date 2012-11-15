{asyncTest, older_emps} = require './lib/service-setup'
{get, invoke} = require '../../src/shiv'
$ = require 'underscore.deferred'

# This query was failing in the webapp.
query =
    model: {"name":"testmodel"},
    select: ["Employee.name","Employee.age", "Employee.department.name"],
    where: [
        {
            path: "Employee.department.name",
            op: "ONE OF",
            code: "A",
            values:["Sales","Accounting"]
        }
    ]

deps = query.where[0].values

exports['all of the results are in one of the specified departments'] = asyncTest 1, (_, assert) ->
    $.when(@service.count(query), @service.rows(query)).then @testCB (c, rows) ->
        assert.eql c, rows.map(get 2).filter((d) -> d in deps).length


{asyncTest, older_emps} = require './lib/service-setup'
{get, invoke} = require '../../src/shiv'

# This query was failing in the webapp.
getQuery = (ids) -> query =
    model: {"name":"testmodel"},
    select: ["Employee.name","Employee.age", "Employee.department.name"],
    where: [{"path":"Employee","op":"IN","code":"A","ids":ids}]

exports['gets results'] = asyncTest 1, (beforeExit, assert) ->
    @service.records(older_emps)
        .then(invoke 'map', get 'objectId')
        .then(getQuery)
        .then(@service.count)
        .then @testCB (c) -> assert.eql 46, c


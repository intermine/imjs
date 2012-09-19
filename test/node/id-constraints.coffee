{asyncTest, older_emps} = require './lib/service-setup'

# This query was failing in the webapp.
query = {"model":{"name":"testmodel"},"select":["Employee.name","Employee.age", "Employee.department.name"],"where":[{"path":"Employee","op":"IN","code":"A"}]}

exports['gets results'] = asyncTest 1, (beforeExit, assert) ->
    s = @service
    rt = @runTest
    s.query older_emps, (q) ->
        q.records (emps) ->
            query.where[0].ids = emps.map (e) -> e.objectId
            s.query query, (id_q) ->
                el = emps.length
                id_q.count (c) -> rt () -> assert.eql c, el, "expected #{ c } == #{ el }"


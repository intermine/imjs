{asyncTest, older_emps} = require './lib/service-setup'

# This query was failing in the webapp.
query = {"model":{"name":"testmodel"},"select":["Employee.name","Employee.age", "Employee.department.name"],"where":[{"path":"Employee.department.name","op":"NONE OF","code":"A","values":["Sales","Accounting"]}]}

exports['gets results'] = asyncTest 2, (beforeExit, assert) ->
    @service.query query, (q) =>
        q.count (c) => @runTest () -> assert.ok c > 0, "#{ c } > 0"
        q.rows (rows) => @runTest () -> assert.eql 0, rows.filter((r) -> r[2] in ['Sales', 'Accounting']).length


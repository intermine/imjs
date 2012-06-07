{asyncTest, older_emps} = require './lib/service-setup'

# This query was failing in the webapp.
query = {"model":{"name":"testmodel"},"select":["Employee.name","Employee.age", "Employee.department.name"],"where":[{"path":"Employee.department.name","op":"ONE OF","code":"A","values":["Sales","Accounting"]}]}

exports['gets results'] = asyncTest 2, (beforeExit, assert) ->
    @service.query query, (q) => q.rows (rows) =>
        @runTest () -> assert.eql 0, rows.filter((r) -> r[2] not in ['Sales', 'Accounting']).length
        @runTest () -> assert.eql rows.length, rows.filter((r) -> r[2] in ['Sales', 'Accounting']).length



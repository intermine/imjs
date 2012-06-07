{asyncTest, older_emps} = require './lib/service-setup'

# This query was failing in the webapp.
query = {"model":{"name":"testmodel"},"select":["Employee.name","Employee.age"],"where":[{"path":"Employee.department.name","op":"NONE OF","code":"A","values":["Sales","Accounting"]}]}

exports['gets results'] = asyncTest 1, (beforeExit, assert) ->
    @service.query query, (q) => q.count (c) => @runTest () -> assert.ok c > 0, "#{ c } > 0"


{asyncTest, older_emps} = require './lib/service-setup'

query =
    select: '*'
    from: 'Employee'
    aliases:
        'Employee.name': "Foo"
        'Employee.department.name': 'Bar'

checkAliases = (check) ->
    check 'name', 'Foo'
    check 'department.name', 'Bar'

exports['path aliases'] = asyncTest 2, (beforeExit, A) ->
    checker = (q) => (path, aka) => q.getPathInfo(path).getDisplayName @testCB (dn) ->
        A.eql aka, dn
    @service.query(query).then(checker).then checkAliases
        
exports['path aliases - promises'] = asyncTest 2, (beforeExit, A) ->
    checker = (q) => (path, aka) => q.getPathInfo(path).getDisplayName().then @testCB (dn) ->
        A.eql aka, dn
    @service.query(query).then(checker).then checkAliases


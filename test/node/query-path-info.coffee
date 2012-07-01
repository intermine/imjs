{asyncTest, older_emps} = require './lib/service-setup'

exports['path aliases'] = asyncTest 2, (beforeExit, assert) ->
    query =
        select: '*'
        from: 'Employee'
        aliases:
            'Employee.name': "Foo"
            'Employee.department.name': 'Bar'

    @service.query query, (q) =>
        q.getPathInfo('name').getDisplayName (name) =>
            @runTest () -> assert.eql name, 'Foo'
        q.getPathInfo('department.name').getDisplayName (name) =>
            @runTest () -> assert.eql name, 'Bar'


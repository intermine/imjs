{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold}  = require '../../src/shiv'

exports['can retrieve the user name'] = asyncTest 1, (beforeExit, assert) ->
    @service.whoami (u) => @runTest () -> assert.eql 'intermine-test-user', u.username

{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold}  = require '../../src/util'

me = 'intermine-test-user'

exports['can retrieve the user name'] = asyncTest 1, (beforeExit, assert) ->
    @service.whoami @testCB (u) -> assert.eql me, u.username

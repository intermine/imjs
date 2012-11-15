{asyncTest} = require './lib/service-setup'

exports['Can manage user preferences'] = asyncTest 2, (beforeExit, assert) ->
    @service.whoami (u) =>
        u.setPreference(testpref: 'TestPrefVal')
            .then(@testCB -> assert.eql 'TestPrefVal', u.preferences.testpref)
            .then( -> u.clearPreference 'testpref')
            .then(@testCB -> assert.ok !u.preferences['testpref']?)

exports['Can manage user preferences: using lists'] = asyncTest 3, (beforeExit, assert) ->
    @service.whoami (u) =>
        u.setPreferences([['testpref1', 'TestPrefVal'], ['testpref2', 'TestPrefVal2']])
            .then(@testCB -> assert.eql u.preferences.testpref1, 'TestPrefVal'; assert.eql u.preferences.testpref2, 'TestPrefVal2')
            .then( -> u.clearPreference 'testpref1')
            .then(@testCB -> assert.ok !u.preferences['testpref1']?)
            .then( -> u.clearPreference 'testpref2')
            .then(@testCB -> assert.ok !u.preferences['testpref2']?)


{asyncTest} = require './lib/service-setup'

exports['Can manage user preferences'] = asyncTest 2, (beforeExit, assert) ->
    failer = () => @runTest () -> assert.ok(false)
    @service.whoami (u) =>
        u.setPreference(testpref: 'TestPrefVal').
            pipe((@testCB -> assert.eql(u.preferences.testpref, 'TestPrefVal')), failer).
            pipe( -> u.clearPreference('testpref')).
            pipe((@testCB -> assert.ok(!u.preferences['testpref']?)), failer)

exports['Can manage user preferences: using lists'] = asyncTest 3, (beforeExit, assert) ->
    failer = () => @runTest () -> assert.ok(false)
    @service.whoami (u) =>
        u.setPreferences([['testpref1', 'TestPrefVal'], ['testpref2', 'TestPrefVal2']]).
            pipe((@testCB -> assert.eql(u.preferences.testpref1, 'TestPrefVal'); assert.eql(u.preferences.testpref2, 'TestPrefVal2')), failer).
            pipe( -> u.clearPreference('testpref1')).
            pipe((@testCB -> assert.ok(!u.preferences['testpref1']?)), failer).
            pipe( -> u.clearPreference('testpref2')).
            pipe((@testCB -> assert.ok(!u.preferences['testpref2']?)), failer)


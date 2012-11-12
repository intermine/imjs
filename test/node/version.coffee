{Service} = require '../../lib/service'
{test, asyncTest} = require './lib/service-setup'

exports['version'] = asyncTest 1, (beforeExit, assert) ->
    @service.fetchVersion (v) => @runTest () -> assert.ok v > 0

exports['version -promise'] = asyncTest 1, (beforeExit, assert) ->
    @service.fetchVersion().fail(@fail).done (v) => @runTest () -> assert.ok v > 0

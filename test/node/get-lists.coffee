{asyncTest, older_emps} = require './lib/service-setup'

exports['can fetch lists'] = asyncTest 2, (beforeExit, assert) ->
    @service.fetchLists (ls) =>
        @runTest () -> assert.ok ls.length > 0
        @runTest () ->
            assert.includes (ls.map (l) -> l.name), 'The great unknowns'

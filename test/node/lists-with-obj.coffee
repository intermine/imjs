{asyncTest, older_emps} = require './lib/service-setup'

exports['can find lists containing an item'] = asyncTest 2, (beforeExit, assert) ->
    @service.fetchListsContaining publicId: 'Brenda', type: 'Employee', (ls) =>
        @runTest () -> assert.eql 2, ls.length, "ls.length is #{ ls.length }, not 2"
        @runTest () -> assert.includes (ls.map (l) -> l.name), 'The great unknowns'

{asyncTest, older_emps} = require './lib/service-setup'
{get} = require '../../src/util'

exports['can find lists containing an item'] = asyncTest 2, (beforeExit, assert) ->
    @service.fetchListsContaining publicId: 'Brenda', type: 'Employee', (ls) =>
        # Depending on the order of execution, Brenda will be in either 2 or 3 lists...
        @runTest -> assert.includes [2, 3], ls.length, "ls.length is #{ ls.length }"
        @runTest -> assert.includes (ls.map get 'name'), 'The great unknowns'

{asyncTest, older_emps} = require './lib/service-setup'

exports['can fetch lists'] = asyncTest 2, (beforeExit, A) ->
    @service.fetchLists (ls) =>
        @runTest ->
            A.ok ls.length > 0
        @runTest ->
            A.includes (l.name for l in ls), 'The great unknowns'

exports['can fetch lists - promises'] = asyncTest 2, (beforeExit, A) ->
    ret = @service.fetchLists()
    ret.done @testCB (ls) ->
        A.ok ls.length > 0
    ret.done @testCB (ls) ->
        A.includes (l.name for l in ls), 'The great unknowns'

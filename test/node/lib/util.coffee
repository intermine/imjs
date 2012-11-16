exports.decap = (x) -> x.replace?(/^\w+\./, '')
exports.lc = (x) -> x.toLowerCase()

exports.LOG = (args...) -> console.log "LOG", args...
exports.ERR = (args...) -> console.error "ERROR", args...

exports.around = (before, after) -> (f) -> (args...) -> before(f, after, args)

exports.testCase = (setup, teardown) -> (f) -> (beforeExit, assert) ->
    context = setup()
    bound = -> teardown.call(context)
    beforeExit(bound) if teardown?
    f.call(context, beforeExit, assert)

exports.fail = (testCase, assert) -> (e) ->
    testCase.runTest -> assert.ok false, (e.stack or e)

exports.pass = (testCase, assert) -> () -> testCase.runTest -> assert.ok true

exports.asyncTestCase = (setup, teardown) -> (n, f) -> exports.testCase(setup, teardown) (beforeExit, assert) ->
    done = 0
    test = @
    @beforeExit = beforeExit
    @assert = assert
    @pass = exports.pass(@, assert)
    @fail = exports.fail(@, assert)
    @failN = (n) -> (e) ->
        console.error (e.stack or e)
        test.fail("Aggregated failure") for _ in [1 .. n]
    @runTest = (toRun) ->
        try
            done++
            toRun()
        catch e
            throw e
    @testCB = (toRun) => (args...) => @runTest -> toRun args... # Shortcut for passing tests into deferred pipes
    beforeExit () -> assert.equal n, done, "Expected #{ n } tests: ran #{ done }"
    f.call(@, beforeExit, assert)


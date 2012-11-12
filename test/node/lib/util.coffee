exports.decap = (x) -> x.replace?(/^\w+\./, '')
exports.lc = (x) -> x.toLowerCase()

exports.around = (before, after) -> (f) -> (args...) -> before(f, after, args)

exports.testCase = (setup, teardown) -> (f) -> (beforeExit, assert) ->
    context = setup()
    beforeExit(teardown) if teardown?
    f.call(context, beforeExit, assert)

exports.fail = (testCase, assert) -> () -> testCase.runTest -> assert.ok false
exports.pass = (testCase, assert) -> () -> testCase.runTest -> assert.ok true

exports.asyncTestCase = (setup, teardown) -> (n, f) -> exports.testCase(setup, teardown) (beforeExit, assert) ->
    done = 0
    @beforeExit = beforeExit
    @assert = assert
    @pass = exports.pass(@, assert)
    @fail = exports.pass(@, assert)
    @runTest = (toRun) ->
        try
            toRun()
            done++
        catch err # At multiple layers of depth, these got surpressed.
            console.error err
            throw err
    @testCB = (toRun) => () => @runTest(toRun) # Shortcut for passing tests into deferred pipes
    beforeExit () -> assert.equal n, done, "Expected #{ n } tests: ran #{ done }"
    f.call(@, beforeExit, assert)


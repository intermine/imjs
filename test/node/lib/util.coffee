exports.decap = (x) -> x.replace?(/^\w+\./, '')
exports.lc = (x) -> x.toLowerCase()

exports.LOG = (args...) -> console.log "LOG", args...
exports.ERR = (args...) -> console.error "ERROR", args...

exports.around = (before, after) -> (f) -> (args...) -> before(f, after, args)

exports.testCase = (setup, teardown) -> (f) -> (beforeExit, assert) ->
    context = setup()
    wrapped = -> teardown.call(context)
    beforeExit(wrapped) if teardown?
    f.call(context, beforeExit, assert)

exports.fail = (testCase, assert) -> () ->
    console.error.appy(console, arguments)
    testCase.runTest -> assert.ok false

exports.pass = (testCase, assert) -> () -> testCase.runTest -> assert.ok true

exports.asyncTestCase = (setup, teardown) -> (n, f) -> exports.testCase(setup, teardown) (beforeExit, assert) ->
    done = 0
    test = @
    @beforeExit = beforeExit
    @assert = assert
    @pass = exports.pass(@, assert)
    @fail = exports.pass(@, assert)
    @failN = (n) -> (e) ->
        console.log "IN FAIL-N"
        console.error e
        test.fail() for _ in [1 .. n]
    @runTest = (toRun) ->
        try
            toRun()
            done++
        catch e
            throw e
    @testCB = (toRun) => (args...) => @runTest -> toRun args... # Shortcut for passing tests into deferred pipes
    beforeExit () -> assert.equal n, done, "Expected #{ n } tests: ran #{ done }"
    f.call(@, beforeExit, assert)


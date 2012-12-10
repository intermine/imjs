{Deferred} = require 'underscore.deferred'
{funcutils: {invoke}} = require './fixture'

clear = (service, name) -> () -> Deferred ->
    service.fetchList(name).then(invoke 'del').always(@resolve)

deferredTest = DT = (test) -> (args...) -> Deferred ->
    try
        ret = test args...
        if ret and ret.then and ret.fail and ret.done
            ret.fail @reject
            ret.done @resolve
        else
            @resolve ret
    catch e
        @reject new Error(e)

report = (done, promise) -> promise.fail(done).done -> done()

eventually = (test) -> (done) -> report done, @promise.then DT test

promising = (p, test) -> (done) -> report done, p.then DT test

prepare = (promiser) -> (done) -> report done, @promise = promiser()

always = (fn) -> (done) -> fn().always -> done()

shouldFail = (fn) -> (done) -> fn().fail(-> done()).done (args...) ->
    done new Error "Expected failure, got: #{ args }"

module.exports = {clear, deferredTest, report, eventually, promising, prepare, always, shouldFail}


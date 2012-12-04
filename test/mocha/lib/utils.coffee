{Deferred} = require 'underscore.deferred'
{funcutils: {invoke}} = require './fixture'

clear = (service, name) -> () -> Deferred ->
    service.fetchList(name).then(invoke 'del').always(@resolve)

deferredTest = (test) -> (args...) -> Deferred ->
    try
        @resolve test args...
    catch e
        @reject new Error(e)

report = (done, promise) -> promise.fail(done).done -> done()

eventually = (test) -> (done) -> report done, @promise.then deferredTest test

module.exports = {clear, deferredTest, report, eventually}



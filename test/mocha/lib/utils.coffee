{Deferred} = $ = require 'underscore.deferred'
{funcutils: {invoke}} = require './fixture'

clear = (service, name) -> () -> Deferred ->
    eh = service.errorHandler # Fetch list logs errors, which we don't care about.
    service.errorHandler = ->
    service.fetchList(name)
           .then(invoke 'del')
           .always(-> service.errorHandler = eh)
           .always(@resolve)


cleanSlate = (service) -> always -> service.fetchLists().then (lists) ->
    after (l.del() for l in lists when l.hasTag('test'))

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

after = (promises) -> if promises?.length then $.when.apply($, promises) else Deferred -> @resolve()

report = (done, promise) -> promise.fail(done).done -> done()

eventually = (test) -> (done) -> report done, @promise.then DT test

promising = (p, test) -> (done) -> report done, p.then DT test

prepare = (promiser) -> (done) -> report done, @promise = promiser()

always = (fn) -> (done) -> fn().always -> done()

shouldFail = (fn) -> (done) -> fn().fail(-> done()).done (args...) ->
    done new Error "Expected failure, got: #{ args }"

module.exports = {
  cleanSlate,
  after,
  clear,
  deferredTest,
  report,
  eventually,
  promising,
  prepare,
  always,
  shouldFail
}


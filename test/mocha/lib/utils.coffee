Promise = require 'promise'

{funcutils: {error, invoke}} = require './fixture'

clear = (service, name) -> () -> new Promise (resolve, reject) ->
    eh = service.errorHandler # Fetch list logs errors, which we don't care about.
    service.errorHandler = ->
    replaceErrorHandler = ->
      service.errorHandler = eh
      resolve()
    service.fetchList(name)
           .then(invoke 'del')
           .then(replaceErrorHandler, replaceErrorHandler)

cleanSlate = (service) -> always -> service.fetchLists().then (lists) ->
    after (l.del() for l in lists when l.hasTag('test'))

deferredTest = DT = (test) -> (args...) -> new Promise (resolve, reject) ->
  try
    ret = test args...
    if ret and ret.then?
      ret.then resolve, reject
    else
      resolve ret
  catch e
    reject e

after = (promises) ->
  if promises?.length then Promise.all(promises) else Promise.from(true)

report = (done, promise) -> promise.done (-> done()), done

prepare = (promiser) -> (done) -> report done, @promise = promiser()

eventually = (test) -> (done) -> report done, @promise.then DT test

promising = (p, test) -> (done) -> report done, p.then DT test

always = (fn) -> (done) -> fn().then (-> done()), (-> done())

shouldFail = (fn) -> (done) ->
  onErr = -> done()
  onSucc = (args...) -> done new Error "Expected failure, got: [#{ args.join(', ') }]"
  fn().then onSucc, onErr

needs = (exp) -> (service) -> (fn) -> prepare -> service.fetchVersion().then (actual) ->
  if actual >= exp then fn service else error "Service at #{ actual }, must be >= #{ exp }"

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
  shouldFail,
  needs
}


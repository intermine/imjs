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

after = (promises...) ->
  if promises?.length then Promise.all(promises) else Promise.from(true)

parallel = Promise.all

report = (done, promise) -> promise.done (-> done()), done

prepare = (promiser) -> (done) -> report done, @promise = promiser()

eventually = (test) -> (done) -> report done, @promise.then test

promising = (p, test) -> (done) -> report done, p.then test

always = (fn) -> (done) -> fn().then (-> done()), (-> done())

shouldFail = (fn) -> shouldBeRejected fn()

shouldBeRejected = (promise) -> (done) ->
  onErr = -> done()
  onSucc = (args...) -> done new Error "Expected failure, got: [#{ args.join(', ') }]"
  promise.then onSucc, onErr

needs = (exp) -> (service) -> (fn) -> prepare -> service.fetchVersion().then (actual) ->
  if actual >= exp then fn service else error "Service at #{ actual }, must be >= #{ exp }"

module.exports = {
  cleanSlate,
  after,
  clear,
  report,
  eventually,
  promising,
  prepare,
  always,
  shouldFail,
  shouldBeRejected,
  needs,
  parallel
}


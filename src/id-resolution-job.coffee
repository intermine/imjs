# This module supplies the **IDResolutionJob** class for the **im.js**
# web-service client.
#
# These objects represent jobs submitted to the service. They supply mechanisms for
# checking the status of the job and retrieving the results, or cancelling
# the job if that is required.
#
# This library is designed to be compatible with both node.js
# and browsers.
#

IS_NODE = typeof exports isnt 'undefined'
__root__ = exports ? this

if IS_NODE
  {Deferred} = require('underscore.deferred')
  funcutils = require './util'
  intermine = __root__
else
  {Deferred} = __root__.jQuery
  {intermine} = __root__
  {funcutils} = intermine

{get} = funcutils

class IDResolutionJob

  constructor: (@uid, @service) ->

  fetchStatus:       (cb) => @service.get("ids/#{ @uid }/status").pipe(get 'status').done(cb)

  fetchErrorMessage: (cb) => @service.get("ids/#{ @uid }/status").pipe(get 'message').done(cb)

  fetchResults:      (cb) => @service.get("ids/#{ @uid }/result").pipe(get 'results').done(cb)

  del: (cb) => @service.makeRequest 'DELETE', "ids/#{ @uid }", {}, cb

  poll: (onSuccess, onError, onProgress) ->
    ret = Deferred().done(onSuccess).fail(onError).progress(onProgress)
    resp = @fetchStatus()
    resp.fail ret.reject
    resp.done (status) =>
      ret.notify(status)
      switch status
        when 'SUCCESS' then @fetchResults().then(ret.resolve, ret.reject)
        when 'ERROR' then @fetchErrorMessage().then(ret.reject, ret.reject)
        else @poll ret.resolve, ret.reject, ret.notify
    return ret.promise()

IDResolutionJob.create = (service) -> (uid) -> new IDResolutionJob(uid, service)

intermine.IDResolutionJob = IDResolutionJob

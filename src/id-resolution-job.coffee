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

{id, get, fold, concatMap} = funcutils

ONE_MINUTE = 60 * 1000

class CategoryResults

  constructor: (results) -> @[k] = v for own k, v of results

  getIssueMatches = concatMap get 'matches'

  getMatches: (k) -> if k is 'MATCH' then @matches[k] else (getIssueMatches @matches[k]) ? []

  getMatchIds: (k) -> if k? then (@getMatches(k).map get 'id') else @allMatchIds()

  goodMatchIds: -> @getMatchIds 'MATCH'

  allMatchIds: ->
    combineIds = fold (res, issueSet) => res.concat @getMatchIds issueSet
    combineIds @goodMatchIds(), ['DUPLICATE', 'WILDCARD', 'TYPE_CONVERTED', 'OTHER']

class IdResults

  constructor: (results) ->
    @[k] = v for own k, v of results

  flatten = concatMap id
  getReasons = (match) -> flatten (vals for k, vals of match.identifiers)
  isGood = (match, k) -> not k? or k in getReasons match

  getMatches: (k) -> (match for own id, match of @ when isGood match, k)

  getMatchIds: (k) -> (id for own id, match of @ when isGood match, k)

  goodMatchIds: -> @getMatchIds 'MATCH'

  allMatchIds: -> @getMatchIds()

class IDResolutionJob

  constructor: (@uid, @service) ->

  fetchStatus:       (cb) => @service.get("ids/#{ @uid }/status").pipe(get 'status').done(cb)

  fetchErrorMessage: (cb) => @service.get("ids/#{ @uid }/status").pipe(get 'message').done(cb)

  fetchResults:      (cb) =>
    gettingRes = @service.get("ids/#{ @uid }/result").pipe(get 'results')
    gettingVer = @service.fetchVersion()
    gettingVer.then (v) -> gettingRes.then (results) ->
      if v >= 16 then new CategoryResults(results) else new IdResults(results)

  del: (cb) => @service.makeRequest 'DELETE', "ids/#{ @uid }", {}, cb

  decay: 50 # ms
 
  # Poll the service until the results are available.
  #
  # @example Poll a job
  #   job.poll().then (results) -> handle results
  #
  # @param [Function] onSuccess The success handler (optional)
  # @param [Function] onError The error handler for if the job fails (optional).
  # @param [Function] onProgress The progress handler to receive status updates.
  #
  # @return [Promise<Object>] A promise to yield the results.
  # @see Service#resolveIds
  poll: (onSuccess, onError, onProgress) ->
    ret = Deferred().done(onSuccess).fail(onError).progress(onProgress)
    resp = @fetchStatus()
    resp.fail ret.reject
    backOff = @decay
    @decay = Math.min ONE_MINUTE, backOff * 2
    resp.done (status) =>
      ret.notify(status)
      switch status
        when 'SUCCESS' then @fetchResults().then(ret.resolve, ret.reject)
        when 'ERROR' then @fetchErrorMessage().then(ret.reject, ret.reject)
        else setTimeout (=> @poll ret.resolve, ret.reject, ret.notify), backOff
    return ret.promise()

IDResolutionJob::wait = IDResolutionJob::poll

IDResolutionJob.create = (service) -> (uid) -> new IDResolutionJob(uid, service)

intermine.IDResolutionJob = IDResolutionJob
intermine.CategoryResults = CategoryResults
intermine.IdResults = IdResults

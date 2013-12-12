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

funcutils = require './util'
intermine = exports

{uniqBy, difference, defer, withCB, id, get, fold, concatMap} = funcutils

ONE_MINUTE = 60 * 1000

class CategoryResults

  constructor: (results) -> @[k] = v for own k, v of results

  getStats: (type) -> if type? then @stats[type] else @stats

  getIssueMatches = concatMap get 'matches'

  getMatches: (k) -> if k is 'MATCH' then @matches[k] else (getIssueMatches @matches[k]) ? []

  getMatchIds: (k) -> if k? then (@getMatches(k).map get 'id') else @allMatchIds()

  goodMatchIds: -> @getMatchIds 'MATCH'

  allMatchIds: ->
    combineIds = fold (res, issueSet) => res.concat @getMatchIds issueSet
    combineIds @goodMatchIds(), ['DUPLICATE', 'WILDCARD', 'TYPE_CONVERTED', 'OTHER']

class IdResults

  unique = uniqBy id
  flatten = concatMap id
  getReasons = (match) -> flatten (vals for k, vals of match.identifiers)
  isGood = (match, k) -> not k? or k in getReasons match

  constructor: (results) ->
    @[k] = v for own k, v of results

  getStats: (type) ->
    switch type
      when 'objects' then @getObjectStats()
      when 'identifiers' then @getIdentifierStats()
      else
        objects: @getObjectStats()
        identifiers: @getIdentifierStats()

  getIdentifierStats: ->
    toIdents = (ms) -> unique flatten (ident for ident of match?.identifiers for match in ms)
    matchIdents = toIdents @getMatches 'MATCH'
    allIdents = toIdents @getMatches()
    matches = matchIdents.length
    all = allIdents.length
    issues = (difference allIdents, matchIdents).length
    {matches, all, issues}

  getObjectStats: ->
    matches = @goodMatchIds().length
    all = @allMatchIds().length
    issues = (id for own id, match of @ when 'MATCH' not in getReasons match).length
    {matches, all, issues}

  getMatches: (k) -> (match for own id, match of @ when isGood match, k)

  getMatchIds: (k) -> (id for own id, match of @ when isGood match, k)

  goodMatchIds: -> @getMatchIds 'MATCH'

  allMatchIds: -> @getMatchIds()

class IDResolutionJob

  constructor: (@uid, @service) ->

  fetchStatus:       (cb) => withCB cb, @service.get("ids/#{ @uid }/status").then(get 'status')

  fetchErrorMessage: (cb) => withCB cb, @service.get("ids/#{ @uid }/status").then(get 'message')

  fetchResults:      (cb) =>
    gettingRes = @service.get("ids/#{ @uid }/result").then(get 'results')
    gettingVer = @service.fetchVersion()
    gettingVer.then (v) -> gettingRes.then (results) ->
      if v >= 16 then new CategoryResults(results) else new IdResults(results)

  del: (cb) => withCB cb, @service.makeRequest 'DELETE', "ids/#{ @uid }"

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
    {promise, resolve, reject} = defer()
    promise.then onSuccess, onError
    notify = onProgress ? (->)
    resp = @fetchStatus()
    resp.then null, reject
    backOff = @decay
    @decay = Math.min ONE_MINUTE, backOff * 1.25
    resp.then (status) =>
      notify(status)
      switch status
        when 'SUCCESS' then @fetchResults().then(resolve, reject)
        when 'ERROR' then @fetchErrorMessage().then(reject, reject)
        else setTimeout (=> @poll resolve, reject, notify), backOff
    return promise

IDResolutionJob::wait = IDResolutionJob::poll

IDResolutionJob.create = (service) -> (uid) -> new IDResolutionJob(uid, service)

intermine.IDResolutionJob = IDResolutionJob
intermine.CategoryResults = CategoryResults
intermine.IdResults = IdResults

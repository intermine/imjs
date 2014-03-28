URL                = require 'url'
JSONStream         = require 'JSONStream'
http               = require 'http'
{ACCEPT_HEADER}    = require './constants'
{VERSION}          = require './version'
{error, defer, merge, invoke} = utils = require('./util')

# The user-agent string we will use to identify ourselves
USER_AGENT = "node-http/imjs-#{ VERSION }"

# Pattern to match optional trailing commas
PESKY_COMMA = /,\s*$/

# The urlencoded content-type.
URLENC = "application/x-www-form-urlencoded"

# Get the method we should actually use to make a request of
# method 'x'.
#
# @param [String] x The method I'm thinking of using.
# @return [String] y The method you should actually use.
#
# Not required if the implementation supports all methods.

# Whether or not this service supports the given method
# The default implementation returns true for all inputs.
exports.supports = -> true

# The function to use when streaming results one by
# one from the connection, rather than buffering them all
# in memory.
streaming = (opts, resolve, reject) -> (resp) ->
  resp.pause() # Wait for handlers to attach...
  resp.on 'error', reject
  if resp.statusCode? and resp.statusCode isnt 200
    errors = JSONStream.parse 'error'
    resp.pipe errors
    reject [resp.statusCode, errors]
  else
    results = JSONStream.parse 'results.*'
    resp.pipe(results)
    resolve results

# Get a message that explains what went wrong.
getMsg = ({type, url}, text, e, code) ->
  """Could not parse response to #{ type } #{ url }: "#{ text }" (#{ code }: #{ e })"""

blocking = (opts, resolve, reject) -> (resp) ->
  containerBuffer = ''
  resp.on 'data', (chunk) -> containerBuffer += chunk
  resp.on 'error', reject
  resp.on 'end', ->
    ct = resp.headers['content-type']
    if 'application/json' is ct or /json/.test(opts.dataType) or /json/.test opts.data.format
      if '' is containerBuffer and resp.statusCode is 200
        # No body, but success.
        resolve()
      else
        try
          parsed = JSON.parse containerBuffer
          if err = parsed.error
            reject new Error(err)
          else
            resolve parsed
        catch e
          if resp.statusCode >= 400
            reject new Error(resp.statusCode)
          else
            reject new Error(getMsg opts, containerBuffer, e, resp.statusCode)
    else
      if match = containerBuffer.match /\[ERROR\] (\d+)([\s\S]*)/
        reject new Error(match[2])
      else
        f = if (200 <= resp.statusCode < 400) then resolve else reject
        f containerBuffer

# Return a function to be called in as a method of a service instance.
exports.iterReq = (method, path, format) -> (q, page = {}, cb = (->), eb = (->), onEnd = (->)) ->
  if utils.isFunction(page)
    [page, cb, eb, onEnd] = [{}, page, cb, eb]
  req = merge {format}, page, query: q.toXML()
  attach = (stream) ->
    stream.on 'data', cb
    stream.on 'error', eb
    stream.on 'end', onEnd
    setTimeout (-> stream.resume()), 3 # Allow handlers in promises to attach.
    return stream
  readErrors = ([sc, errors]) ->
    errors.on 'data', eb
    errors.on 'error', eb
    errors.on 'end', onEnd
    errors.resume()
    error sc
  @makeRequest(method, path, req, null, true).then attach, readErrors

rejectAfter = (timeout, reject, promise) ->
  to = setTimeout (-> reject "Request timed out."), timeout
  promise.then -> cancelTimeout to

exports.doReq = (opts, iter) ->
  {promise, resolve, reject} = defer()
  promise.then null, opts.error

  if not opts.url
    throw new Error("No url provided in #{ JSON.stringify opts }")

  if typeof opts.data is 'string'
    postdata = opts.data
    if opts.type in [ 'GET', 'DELETE' ]
      reject("Invalid request. #{ opts.type } requests must not have bodies")
      return promise
  else
    postdata = utils.querystring opts.data

  url = URL.parse(opts.url, true)
  url.method = opts.type
  url.port = url.port || 80
  url.headers =
    'User-Agent': USER_AGENT
    'Accept': ACCEPT_HEADER[opts.dataType]

  if url.method in ['GET', 'DELETE'] and postdata?.length
    sep = if /\?/.test(url.path) then '&' else '?'
    url.path += sep + postdata
  else
    url.headers['Content-Type'] = (opts.contentType or URLENC) + '; charset=UTF-8'
    url.headers['Content-Length'] = postdata.length

  if 'headers' of opts
    url.headers[k] = v for k, v of opts.headers

  handler = (if iter then streaming else blocking) opts, resolve, reject
  req = http.request url, handler

  req.on 'error', (err) ->
    reject new Error("Error: #{ url.method } #{ opts.url }: #{ err }")

  if url.method in [ 'POST', 'PUT' ]
    req.write postdata
  req.end()

  timeout = opts.timeout
  if timeout > 0
    rejectAfter timeout, reject, promise

  return promise


httpinvoke         = require 'httpinvoke'
{ACCEPT_HEADER}    = require './constants'
{error, merge}     = utils = require('./util')

# Pattern to match optional trailing commas
PESKY_COMMA = /,\s*$/

# The urlencoded content-type.
URLENC = "application/x-www-form-urlencoded"

# Get the method we should actually use to make a request of
# method 'x'.
#
# @param [String] x The method I'm thinking of using.
# @return [String] y The method you should actually use.
exports.getMethod = (x) -> x

# Whether or not this service supports the given method
# The default implementation returns true for all inputs.
exports.supports = -> true

# The function to use when streaming results one by
# one from the connection, rather than buffering them all
# in memory.
streaming = -> (data) -> 'on': (evt, cb) ->
  switch evt
    when 'data' then (cb res for res in data.results)
    when 'end' then cb()

# Return a function to be called in as a method of a service instance.
exports.iterReq = (method, path, format) -> (q, page = {}, cb = (->), eb = (->), onEnd = (->)) ->
    if utils.isFunction(page)
      [page, cb, eb, onEnd] = [{}, page, cb, eb]
    req = merge {format}, page, query: q.toXML()

    attach = (stream) ->
      stream.on 'data', cb
      stream.on 'end', onEnd
      return stream

    @makeRequest(method, path, req, null, true).then attach, eb

exports.doReq = (opts, iter) ->
  method = opts.type
  url = opts.url
  headers = 'Accept': ACCEPT_HEADER[opts.dataType]
  isJSON = (/json/.test(opts.dataType) or /json/.test(opts.data?.format))

  if opts.data?
    postdata = if typeof opts.data is 'string'
      opts.data
    else if "application/json" is opts.contentType
      JSON.stringify opts.data
    else
      utils.querystring opts.data

    if method in ['GET', 'DELETE'] and postdata?.length
      url += '?' + postdata
      postdata = undefined
    else
      headers['Content-Type'] = (opts.contentType or URLENC) + '; charset=UTF-8'
      headers['Content-Length'] = postdata.length

  options =
    timeout: opts.timeout
    headers: headers
    inputType: 'text'
    input: postdata
    outputType: if isJSON then 'json' else 'text'
    converters:
      'text json': JSON.parse

  resp = httpinvoke(url, method, options)
  resp.then(opts.success, opts.error)

  if iter
    return resp.then streaming

  return resp


httpinvoke              = require 'httpinvoke'
Promise                 = require './promise'
{ACCEPT_HEADER}         = require './constants'
{withCB, success, error, merge} = utils = require('./util')

# Pattern to match optional trailing commas
PESKY_COMMA = /,\s*$/

# The urlencoded content-type.
URLENC = "application/x-www-form-urlencoded"

IE_VERSION = -1

if navigator.appName is 'Microsoft Internet Explorer'
  ua = navigator.userAgent
  re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})")
  if matches = ua.match re
    IE_VERSION = parseFloat matches[1]

# Get the method we should actually use to make a request of
# method 'x'.
#
# @param [String] x The method I'm thinking of using.
# @return [String] y The method you should actually use.
exports.getMethod = (x) ->
  switch x
    when "PUT" then "POST"
    when "DELETE" then "GET"
    else x

# Whether or not this service supports the given method
# The default implementation returns true for all inputs.
exports.supports = (x) ->
  if (0 < IE_VERSION < 10) and x in ['PUT', 'DELETE']
    false # IE's XDomainRequest object is awful.
  else
    true

# The function to use when streaming results one by
# one from the connection, rather than buffering them all
# in memory.
streaming = (data) -> resume: (->), pause: (->), on: (evt, cb) ->
  switch evt
    when 'data' then (cb res for res in data.results)
    when 'end' then cb()

# Return a function to be called in as a method of a service instance.
exports.iterReq = (method, path, format) -> (q, page = {}, cb, eb, onEnd) ->
  if utils.isFunction(page)
    [page, cb, eb, onEnd] = [{}, page, cb, eb]
  req = merge {format}, page, query: q.toXML()

  attach = (stream) ->
    console.log "Attaching"
    stream.on 'data', cb if cb?
    stream.on 'end', onEnd if onEnd?
    return stream

  withCB eb, @makeRequest(method, path, req, null, true).then attach

check = (response) ->
  sc = response?.statusCode
  if (sc? and 200 <= sc < 400) or ((not sc?) and response?.body?) #ie8 => no status code.
    response.body
  else
    msg = "Bad response: #{ sc }"
    err = if response.body?.error
      response.body.error
    else if e = response.body?.match?( /\[ERROR\] (\d+)([\s\S]*)/ )
      e[2]

    msg += ": #{ err }" if err?
    error new Error(msg)

CHARSET = "; charset=UTF-8"
CONVERTERS = 'text json': JSON.parse

annotateError = (url) -> (err) ->
  throw new Error("Request to #{ url } failed: #{ err }")

exports.doReq = (opts, iter) ->
  method = opts.type
  url = opts.url
  headers = (opts.headers ? {})
  headers.Accept = ACCEPT_HEADER[opts.dataType]
  isJSON = (/json/.test(opts.dataType) or /json/.test(opts.data?.format))

  if opts.data?
    postdata = if typeof opts.data is 'string'
      opts.data
    else if "application/json" is opts.contentType
      JSON.stringify opts.data
    else
      utils.querystring opts.data

    if method in ['GET', 'DELETE'] and postdata?.length
      sep = if /\?/.test(url) then '&' else '?'
      url += sep + postdata
      postdata = undefined
    else
      headers['Content-Type'] = (opts.contentType or URLENC) + CHARSET

  options =
    timeout: opts.timeout
    headers: headers
    outputType: if isJSON then 'json' else 'text'
    corsExposedHeaders: ['Content-Type'],
    converters: CONVERTERS

  if postdata?
    options.inputType = 'text'
    options.input = postdata

  resp = Promise.from(httpinvoke url, method, options).then check, annotateError url
  resp.then(opts.success, opts.error)

  if iter
    return resp.then streaming

  return resp


{jQuery, _, intermine, XDomainRequest} = @
http = (intermine.http ?= {})
{ACCEPT_HEADER} = intermine.constants
{get, error} = intermine.funcutils

do ->
  converters = {}
  for format, header of ACCEPT_HEADER
    converters["text #{ format }"] = jQuery.parseJSON
  jQuery.ajaxSetup
    accepts: ACCEPT_HEADER
    contents: {json: /json/}
    converters: converters

# A pipe for checking the webservice response.
CHECKING_PIPE = (response) -> jQuery.Deferred ->
  if response.wasSuccessful
    @resolve response
  else
    @reject response.error, response

# Process the errors returned from the webservice.
ERROR_PIPE = (f = (->)) -> (xhr, textStatus, e) ->
  return if xhr?.status is 0 # Aborted
  try
    f JSON.parse(xhr.responseText).error
  catch e
    f textStatus

inIE9 = XDomainRequest?
mappingForIE = PUT: 'POST', DELETE: 'GET'

if inIE9
  http.getMethod = (x) -> mappingForIE[x] ? x
  http.supports = (m) -> m not of mappingForIE
else
  http.getMethod = (x) -> x
  http.supports = -> true

wrapCbs = (cbs) ->
  if _.isArray cbs
    return [] unless cbs.length
    [doThis, err, atEnd] = cbs
    _doThis = (rows) -> _.each(rows, doThis ? ->)
    return [_doThis, err, atEnd]
  else
    _doThis = (rows) -> _.each(rows, cbs ? ->)
    return [_doThis]

http.iterReq = (method, path, fmt) -> (q, page = {}, doThis = (->), onErr = (->), onEnd = (->)) ->
  if arguments.length is 2 and _.isFunction page
    [doThis, page] = [page, {}]
  req     = _.extend {format: fmt}, page, query: q.toXML()
  _doThis = (rows) -> rows.forEach doThis
  @makeRequest(method, path, req)
    .fail(onErr)
    .pipe(get 'results')
    .done(doThis)
    .done(onEnd)

# Very thin wrapper around ajax, just to ensure errors are handled
# correctly.
http.doReq = (opts) ->
  errBack = (opts.error or @errorHandler)
  opts.error = ERROR_PIPE errBack
  def = jQuery.Deferred ->
    resp = jQuery.ajax opts
    resp.then => @resolve arguments...
    resp.fail ERROR_PIPE (err) => @reject err
  def.promise()

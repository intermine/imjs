{jQuery, intermine, XDomainRequest} = @
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
ERROR_PIPE = (xhr, textStatus, e) ->
    try
        JSON.parse(xhr.responseText).error
    catch e
        textStatus

inIE9 = XDomainRequest?
mappingForIE = PUT: 'POST', DELETE: 'GET'

if inIE9
    http.getMethod = (x) -> mappingForIE[x] ? x
    http.supports = (m) -> x not of mappingForIE
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

http.iterReq = (method, path, format) -> (q, page = {}, cbs = []) ->
    try
        [cbs, page] = [page, {}] if (_.isFunction(page) or _.isArray(page))
        req = _.extend {format}, page, query: q.toXML()
        [doThis, fail, onEnd] = wrapCbs(cbs)
        @makeRequest(method, path, req).fail(fail).pipe(get 'results').then(doThis).done(onEnd)
    catch e
        error e.stack ? e


http.doReq = (opts) ->
    errBack = (opts.error or @errorHandler)
    opts.error = _.compose errBack, ERROR_PIPE
    return jQuery.ajax(opts).pipe(CHECKING_PIPE).fail(errBack)

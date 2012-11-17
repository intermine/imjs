{jQuery, intermine, XDomainRequest} = @
http = (intermine.http ?= {})
#
# The Accept headers that correspond to each data-type.
ACCEPT_HEADER =
    "json": "application/json",
    "jsonobjects": "application/json;type=objects",
    "jsontable": "application/json;type=table",
    "jsonrows": "application/json;type=rows",
    "jsoncount": "application/json;type=count",
    "jsonp": "application/javascript",
    "jsonpobjects": "application/javascript;type=objects",
    "jsonptable": "application/javascript;type=table",
    "jsonprows": "application/javascript;type=rows",
    "jsonpcount": "application/javascript;type=count"

do ->
    converters = {}
    for format, header of ACCEPT_HEADER
        converters["text #{ format }"] = jQuery.parseJSON
    jQuery.ajaxSetup
        accepts: ACCEPT_HEADER
        contents: {json: /json/}
        converters: converters

# A pipe for checking the webservice response.
CHECKING_PIPE = (response) -> Deferred ->
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
        [doThis, err, atEnd] = cbs
        [((rows) -> _.each(rows, doThis)), err, atEnd]
    else
        [(rows) -> _.each rows, cbs]

http.iterReq = (format) -> (q, page = {}, cbs = []) ->
    if !cbs? and not (page.start? or page.size?)
        [page, cbs] = [{}, page]
    _cbs = wrapCbs(cbs)
    req = _.extend {format}, page, query: q.toXML()
    [doThis, fail, onEnd] = _cbs
    @post(QUERY_RESULTS_PATH, req, _cbs).done(onEnd)


http.doReq = (opts) ->
    errBack = (opts.error or @errorHandler)
    opts.error = _.compose errBack, ERROR_PIPE
    return jQuery.ajax(opts).pipe(CHECKING_PIPE).fail(errBack)

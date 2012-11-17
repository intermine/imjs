{BufferedResponse} = require('buffered-response')
http               = require('http')
URL                = require('url')
qs                 = require('querystring')

# Pattern to match optional trailing commas
PESKY_COMMA = /,\s*$/

# The urlencoded content-type.
URLENC = "application/x-www-form-urlencoded"

# Get the method we should actually use to make a request of
# method 'x'.
#
# @param [String] x The method I'm thinking of using.
exports.getMethod = (x) -> x

# Whether or not this service supports the given method
# The default implementation returns true for all inputs.
exports.supports = -> true

streaming = (ret, opts) -> (resp) ->
    containerBuffer = ''
    char0 = if opts.data.format is 'json' then '[' else '{'
    charZ = if opts.data.format is 'json' then ']' else '}'
    toItem = (line, idx) ->
        try
            parsed = JSON.parse line.replace PESKY_COMMA, ''
            return parsed
        catch e
            containerBuffer += line
            lastChar = line[line.length - 1]
            if idx > 0 and (lastChar is ',' or (lastChar is char0 && line[0] is charZ))
                # This should have parsed
                iter.emit('error', e, line)
            return undefined
    onlyDefinedItems = (item) -> item?
    onEnd = ->
        # Check the container on end to make sure all was well.
        try
            container = JSON.parse containerBuffer
            if container.error
                iter.emit 'error', new Error(container.error)
        catch e
            iter.emit 'error', "Mal-formed JSON response: #{ containerBuffer }"

    iter = new BufferedResponse(resp, 'utf8')
        .map(toItem)
        .filter(onlyDefinedItems)
        .each(opts.success)
        .error(opts.error)
        .done(onEnd)

    ret.resolve iter

blocking = (ret, opts) -> (resp) ->
    containerBuffer = ''
    ret.done(opts.success)
    resp.on 'data', (chunk) -> containerBuffer += chunk
    resp.on 'error', (e) -> ret.reject(e)
    resp.on 'end', ->
        if /json/.test opts.data.format
            if '' is containerBuffer and resp.statusCode is 200
                # No body, but all-good.
                ret.resolve()
            else
                try
                    parsed = JSON.parse containerBuffer
                    if err = parsed.error
                        ret.reject new Error(err)
                    else
                        ret.resolve parsed
                catch e
                    if resp.statusCode >= 400
                        ret.reject new Error(resp.statusCode)
                    else
                        ret.reject new Error "Could not parse response to #{ opts.type } #{ opts.url }: '#{ containerBuffer }' (#{ e })"
        else
            if e = containerBuffer.match /\[Error\] (\d+)(.*)/m
                ret.reject new Error(e[2])
            else
                ret.resolve containerBuffer

exports.iterReq = (format) -> (q, page = {}, cbs = []) ->
        if !cbs? and not (page.start? or page.size?)
            [page, cbs] = [{}, page]
        if _.isFunction cbs
            cbs = [cbs]
        req = _.extend {format}, page, query: q.toXML()
        [doThis, onErr, onEnd] = cbs
        @makeRequest('POST', QUERY_RESULTS_PATH, req, null, true)
            .fail(onErr)
            .done(invoke 'each', doThis)
            .done(invoke 'error', onErr)
            .done(invoke 'done', onEnd)

exports.doReq = (opts, iter) -> Deferred ->
        @fail opts.error
        @done opts.success
        if _.isString opts.data
            postdata = opts.data
            if opts.type in [ 'GET', 'DELETE' ]
                return ret.reject("Invalid request. #{ opts.type } requests must not have bodies")
        else
            postdata = qs.stringify opts.data
        url = URL.parse(opts.url, true)
        url.method = opts.type
        url.port = url.port || 80
        url.headers =
            'User-Agent': 'node-http/imjs',
            'Accept': ACCEPT_HEADER[opts.dataType]
        if url.method in ['GET', 'DELETE'] and _.size opts.data
            url.path += '?' + postdata
        else
            url.headers['Content-Type'] = (opts.contentType or URLENC) + '; charset=UTF-8'
            url.headers['Content-Length'] = postdata.length

        req = http.request url, (if iter then streaming else blocking) @, opts

        req.on 'error', @reject

        if url.method in [ 'POST', 'PUT' ]
            req.write postdata
        req.end()


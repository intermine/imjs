"use strict";

(function(exports, IS_NODE) {

    var Model, Query, List, _, Deferred, User, ACCEPT_HEADER;
    ACCEPT_HEADER = {
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
    };
    if (IS_NODE) {
        _ = require('underscore')._;
        Deferred = require('jquery-deferred').Deferred;
        var http     = require('http');
        var URL      = require('url');
        var qs       = require('querystring');
        Model        = require('./model').Model;
        Query        = require('./query').Query;
        List         = require('./lists').List;
        User         = require('./user').User;
        var EventEmitter = require('events').EventEmitter;
        var BufferedResponse = require('buffered-response').BufferedResponse;
    } else {
        _ = exports._;
        Deferred = exports.jQuery.Deferred;
        if (typeof exports.intermine === 'undefined') {
            exports.intermine = {};
        }
        exports = exports.intermine;
        var converters = {};
        _.each(_.keys(ACCEPT_HEADER), function(dataType) {
            converters["text " + dataType] = jQuery.parseJSON;
        });
        jQuery.ajaxSetup({accepts: ACCEPT_HEADER, contents: {json: /json/}, converters: converters});
    } 

    var to_query_string = IS_NODE ? qs.stringify : jQuery.param;

    var MODELS = {};
    var SUMMARY_FIELDS = {};
    var slice = Array.prototype.slice;
    var DEFAULT_PROTOCOL = "http://";
    var VERSION_PATH = "version";
    var TEMPLATES_PATH = "templates";
    var LISTS_PATH = "lists";
    var MODEL_PATH = "model";
    var SUMMARYFIELDS_PATH = "summaryfields";
    var QUERY_RESULTS_PATH = "query/results";
    var QUICKSEARCH_PATH = "search";
    var WIDGETS_PATH = "widgets";
    var ENRICHMENT_PATH = "list/enrichment";
    var WITH_OBJ_PATH = "listswithobject";
    var LIST_OPERATION_PATHS = {
        merge: "lists/union",
        intersect: "lists/intersect",
        diff: "lists/diff"
    };
    var IDENTITY = function(x) { return x; };
    var HAS_PROTOCOL = /^https?:\/\//i;
    var HAS_SUFFIX = /service\/?$/i;
    var SUFFIX = "/service/";

    var Service = function(properties) {

        // keep this reference for internal binding issues.
        var __service = this;

        if (typeof Model === 'undefined' && intermine) {
            Model = intermine.Model;
        }
        if (typeof Query === 'undefined' && intermine) {
            Query = intermine.Query;
        }
        if (typeof List === 'undefined' && intermine) {
            List = intermine.List;
        }
        if (typeof User === 'undefined' && intermine) {
            User = intermine.User;
        }
        
        /**
         * The kind of object that the server sends as for every
         * JSON request. A results envelope will be sent for every request, even if the
         * request is unsuccessful.
         * @name ResultsEnvelope
         * @property {boolean} wasSuccessful Whether or not this request was successful. This
         *           property should be checked for streaming requests (such as query results),
         *           as errors can occur while results are being processed.
         * @property {int} statusCode The HTTP error code.
         * @property {String} error A human-readable error message saying what went wrong.
         * @property {String} executionTime The time when this result set was generated. eg: 2012.11.02 16:00::16
         */

        var wrapErrorHandler = function(handler) { return function(xhr, textStatus, e) {
            try {
                return JSON.parse(xhr.responseText);
            } catch (parseError) {
                return textStatus;
            }
        }};

        /**
         * A function that can be passed as the callback to handle
         * the successful completion of an HTTP service request.
         * @name SuccessCallback
         * @param data {ResultsEnvelope} The data received from the server.
         * @return void
         */

        /**
         * A function to wrap an optional callback which extracts
         * a specific property from a results envelope and passes it into
         * the callback if it exists and returns the extracted value.
         * @name ResultProcessor
         * @param cb {ItemProcessor} The optional callback
         * @return {SuccessCallback} A success callback.
         */

        /**
         * A function that handles the results returned from as server call.
         * @name ItemProcessor
         * @param item The item to process
         * @param data {ResultsEnvelope} The original envelope, possibly containing metadata.
         */

        /**
         * A function to generate a function that wraps an optional callback and passes into
         * it the value of a specific property of the first argument passed in, returning that
         * value.
         * @private
         * @param key The key to extract from the eventual results object.
         * @return {ResultProcessor} A result processor.
         */
        var getResultProcessor = function(key) { return function(cb) { return function(response) {
            var deferred = Deferred(), item = response[key];
            if (!response.wasSuccessful) {
                deferred.reject(response.error);
            } else {
                (cb || IDENTITY)(item, response);
                deferred.resolve(item, response);
            }
            return deferred.promise();
        }}};

        /**
         * A function to wrap an optional callback which extracts the
         * 'results' property from the results envelope and passes it into
         * the callback if it exists and returns the extracted value.
         * @private
         * @param cb {function} The optional callback
         * @return Whatever the value of the 'results' property is.
         */
        var getResulteriser = getResultProcessor('results');

        /**
         * Get the format for a request, given a default.
         * Basically this function is here to make sure that
         * we do jsonp requests when we have to.
         * @private
         * @param def The default format for this request.
         */
        var getFormat = function(def) {
            var format = def || "json";
            if (!(IS_NODE || jQuery.support.cors)) {
                format = format.replace("json", "jsonp");
            }
            return format;
        };

        /**
         * Short-cut for the common POST operation. For more fine-grained
         * request handling use makeRequest.
         * @this {Service}
         * @param path {string} The path to the resource to post to.
         * @param data {Object} The data to post to the resource.
         * @param cb {function} An optional callback.
         * @return {Deferred} A promise to perform this action.
         */
        this.post = function(path, data, cb) {
            return this.makeRequest(path, data, cb, 'POST');
        };

        /**
         * Short-cut for the common GET operation. For more fine-grained
         * request handling use makeRequest.
         * @this {Service}
         * @param {string} path The path to the resource to post to.
         * @param {Object.<string, string>} data An optional set of data to send to the server.
         * @param {SuccessCallback} cb An optional callback.
         * @return {Deferred} A promise to perform this action.
         */
        this.get = function(path, data, cb) {
            if(!cb && data && _.isFunction(data)) {
                cb = data; // Allow calling with get(path, cb);
                data = {};
            }
            return this.makeRequest(path, data, cb, 'GET');
        }

        /**
        * Performs a get request for data against a url. 
        * This method makes use of jsonp where available.
        */
        this.makeRequest = function(path, data, cb, method, itemByItem) {
            method = (method || "GET");
            cb = (cb || IDENTITY);
            data = (data || {});

            var url   = this.root + path;
            var errorCB = this.errorHandler;
            if (cb[0] && cb[1]) {
                errorCB = cb[1];
                cb = cb[0];
            }

            if (_.isArray(data)) { // We also accept lists of pairs.
                data = _.foldl(data, function(m, pair) { m[pair[0]] = pair[1]; return m;}, {});
            }

            if (this.token) {
                data.token = this.token;
            }
            data.format = getFormat(data.format);

            if (/jsonp/.test(data.format)) {
                // Tunnel the method in a parameter.
                data.method = method;
                method = "GET"; 
                url += "?callback=?";
            }
            // IE requires that we tunnel DELETE and PUT requests.
            if (!this.supports(method)) {
                data.method = method;
                method = this.getEffectiveMethod(method);
            }

            if (method === "DELETE") {
                // grumble grumble struts grumble grumble...
                // (struts won't read query data from the request body
                // of DELETE requests).
                url += "?" + to_query_string(data);
            }

            return this.doReq({
                data: data,
                dataType: data.format,
                success: cb,
                error: errorCB,
                url: url,
                type: method
            }, itemByItem);
        };

        this.supports = function() { return true; };
        this.getEffectiveMethod = IDENTITY;

        if (IS_NODE) {
            this.rowByRow = function(q, page, cbs) {
                // Allow calling as rows(q, cb)
                if (_(cbs).isUndefined() && _(page).isFunction()) {
                    cbs = page;
                    page = {};
                }
                page = page || {};
                var req = _(page).extend({query: q.toXML()});
                return this.makeRequest(QUERY_RESULTS_PATH, req, cbs, 'POST', true);
            };

            this.recordByRecord = function(q, page, cbs) {
                // Allow calling as records(q, cb)
                if (_(cbs).isUndefined() && _(page).isFunction()) {
                    cbs = page;
                    page = {};
                }
                page = page || {};
                var req = _(page).extend({query: q.toXML(), format: "jsonobjects"});
                return this.makeRequest(QUERY_RESULTS_PATH, req, cbs, 'POST', true);
            };

            var PESKY_COMMA = /,\s*$/;

            var __doIterableReq = function(ret, opts) { return function(res) {
                 var iter, containerBuffer = "";
                 var char0 = (opts.data.format === 'json') ? '[' : '{';
                 var charZ = (opts.data.format === 'json') ? ']' : '}';
                 iter = new BufferedResponse(res, 'utf8')
                    .map(function(line, idx) {
                        try {
                          var parsed = JSON.parse(line.replace(PESKY_COMMA, ''));
                          return parsed;
                        } catch(e) {
                          containerBuffer += line;
                          var lastChar = line[line.length - 1];
                          if (idx > 0 && (lastChar === ',' || (lastChar === char0 && line[0] === charZ))) {
                              iter.emit('error', e, line); // should have parsed.
                          }
                          return undefined;
                        }
                    })
                   .filter(function(item) {return (!!item)})
                   .each(function(item) {
                       try {
                           opts.success(item);
                       } catch (e) {
                           iter.emit('error', e);
                           ret.reject(e);
                       }
                    })
                   .error(opts.error)
                   .done(function() {
                     try {
                         var container = JSON.parse(containerBuffer);
                         if (container.error) {
                             var e = new Error(container.error);
                             ret.reject(e);
                             iter.emit('error', e);
                         }
                     } catch (e) {
                         ret.reject(e, containerBuffer);
                         iter.emit('error', containerBuffer);
                     }
                   });
                ret.resolve(iter);
            }};
            var __doSingletonResult = function(ret, opts) { return function(res) {
                 var contentBuffer = "";
                 ret.then(opts.success);
                 res.on('data', function(chunk) {contentBuffer += chunk});
                 res.on('end', function() {
                     if (opts.data.format.match(/json/)) {
                        var parsed;
                        try {
                            parsed = JSON.parse(contentBuffer);
                            if (parsed.error) {
                                ret.reject(new Error(parsed.error));
                            } else {
                                ret.resolve(parsed);
                            }
                        } catch(e) {
                            ret.reject(new Error("Could not parse buffer (" + contentBuffer + "): " + e));
                        }
                     } else {
                         var e;
                         if (e = contentBuffer.match(/\[Error\] (\d+)(.*)/m)) {
                             ret.reject(new Error(e[2]));
                         } else {
                             ret.resolve(contentBuffer);
                         }
                     }
                 });
            }}

            this.doReq = function(opts, resultByResult) {
                var ret = new Deferred().fail(opts.error);
                var postdata = to_query_string(opts.data);
                var url = URL.parse(opts.url, true);
                url.method = opts.type;
                url.port = url.port || 80;
                url.headers = {'User-Agent': 'node-http/imjs', 'Accept': ACCEPT_HEADER[opts.dataType]};
                if (url.method === 'GET' && _(opts.data).size()) {
                    url.path += "?" + postdata;
                } else if (url.method === 'POST') {
                    url.headers['Content-Type'] = 'application/x-www-form-urlencoded';
                    url.headers['Content-Length'] = postdata.length;
                }
                var req = http.request(url, (resultByResult) ?
                    __doIterableReq(ret, opts) : __doSingletonResult(ret, opts));

                req.on('error', function(e) {
                    ret.reject(e);
                });

                if (url.method === 'POST') {
                    if (this.DEBUG) {
                        console.log("Writing data to " + url.host + "/" + url.path + ": " + postdata);
                    }
                    req.write(postdata);
                }
                req.end();
                return ret;
            };
        } else {
            this.doReq = function(opts) {
                var errorHandler = wrapErrorHandler(opts.error);
                delete opts.error;
                return jQuery.ajax(opts).pipe(IDENTITY, errorHandler);
            }
            if (typeof XDomainRequest !== 'undefined') {
                this.getEffectiveMethod = (function(mapping) {
                    return function(x) { return mapping[x]; }
                })({PUT: "POST", DELETE: "GET"});
                this.supports = function(method) {
                    return this.getEffectiveMethod(method) === method;
                };
            }
            var __wrap_cbs = function(cbs) {
                var wrappedSuccess, error;
                if (cbs[0] && cbs[1]) {
                    wrappedSuccess = function(rows) {
                        _.each(rows, cbs[0]);
                    };
                    error = cb[1];
                    return [wrappedSuccess, error];
                } else {
                    wrappedSuccess = function(rows) {
                        _.each(rows, cbs);
                    };
                    return wrappedSuccess;
                }
            };

            this.rowByRow = function(q, page, cbs) {
                page = page || {};
                var _cbs = __wrap_cbs(cbs), req = _(page).extend({query: q.toXML()});
                return this.post(QUERY_RESULTS_PATH, req, _cbs);
            };

            this.recordByRecord = function(q, page, cbs) {
                page = page || {};
                var _cbs = __wrap_cbs(cbs), req = _(page).extend({query: q.toXML(), format: "jsonobjects"});
                return this.post(QUERY_RESULTS_PATH, req, _cbs);
            };
        }
        this.eachRow = this.rowByRow;
        this.eachRecord = this.recordByRecord;

        var widgeteriser = getResultProcessor('widgets');

        this.widgets = function(cb) {
            return this.get(WIDGETS_PATH).pipe(widgeteriser(cb));
        };

        this.enrichment = function(req, cb) {
            _.defaults(req, {maxp: 0.05});
            return this.makeRequest(ENRICHMENT_PATH, req).pipe(getResulteriser(cb));
        };

        this.search = function(options, cb) {
            if (_(options).isString()) {
                options = {term: options};
            }
            if (!cb && _(options).isFunction()) {
                cb = options;
                options = {};
            }
            options = options || {};
            cb      = cb      || IDENTITY;
            _.defaults(options, {term: "", facets: {}});
            var req = {q: options.term, start: options.start, size: options.size};
            if (options.facets) {
                _(options.facets).each(function(v, k) {
                    req["facet_" + k] = v;
                });
            }
            return this.post(QUICKSEARCH_PATH, req).pipe(function(data) {
                cb(data.results, data.facets);
                return data.results;
            });
        };

        this.count = function(q, cont) {
            var req = {
                query: q.toXML(),
                format: getFormat("jsoncount")
            };
            return this.makeRequest(QUERY_RESULTS_PATH, req, null, "POST").pipe(getResultProcessor('count')(cont));
        };

        this.findById = function(table, objId, cb) {
            var promise = Deferred();
            cb = cb || IDENTITY;
            this.query({from: table, select: ["**"], where: {"id": objId}}, function(q) {
                for (var i = 0; i < q.views.length; i++) {
                    var view = q.views[i];
                    var parts = view.split('.');
                    if (parts.length > 2) {
                        q.addJoin(parts.slice(0, parts.length - 1).join('.'));
                    }
                }
                q.records(function(rs) {
                    cb(rs[0]);
                    promise.resolve(rs[0]);
                }).fail(promise.reject);
            }).fail(promise.reject);
            return promise;
        };

        this.whoami = function(cb) {
            cb = cb || IDENTITY;
            var self = this, promise = Deferred(), handler = function(resp) {
                var user = new User(self, resp.user);
                cb(user);
                promise.resolve(user);
                return user;
            };
            self.fetchVersion(function(v) {
                if (v < 9) {
                    var msg = "The who-am-i service requires version 9, this is only version " + v;
                    promise.reject("not available", msg);
                } else {
                    self.makeRequest("user/whoami").pipe(handler, promise.reject);
                }
            }).fail(promise.reject);
            return promise;
        };

        var doPagedRequest = function(path, page, cb, q, format) {
            if (_(cb).isUndefined() && _(page).isFunction()) {
                cb = page;
                page = {};
            }
            var req = _(page || {}).extend({query: q.toXML(), format: format});
            return this.post(path, req).pipe(getResulteriser(cb));
        };

        this.table = function(q, page, cb) {
            return doPagedRequest.call(this, QUERY_RESULTS_PATH, page, cb, q, "jsondatatable");
        };

        this.records = function(q, page, cb) {
            return doPagedRequest.call(this, QUERY_RESULTS_PATH, page, cb, q, "jsonobjects");
        };

        this.rows = function(q, page, cb) {
            return doPagedRequest.call(this, QUERY_RESULTS_PATH, page, cb, q, "json");
        };

        this.tableRows = function(q, page, cb) {
            return doPagedRequest.call(this, QUERY_RESULTS_PATH + '/tablerows', page, cb, q, "json");
        };

        var DEFAULT_ERROR_HANDLER = function(error) {
            if (console.error) {
                console.error(error);
            } else if (console.log) {
                console.log(error);
            }
        };

        var constructor = _.bind(function(properties) {
            var root = properties.root;
            if (!HAS_PROTOCOL.test(root)) {
                root = DEFAULT_PROTOCOL + root;
            }
            if (!HAS_SUFFIX.test(root)) {
                root = root + SUFFIX;
            }
            root = root.replace(/ice$/, "ice/");
            this.errorHandler = (properties.errorHandler || DEFAULT_ERROR_HANDLER);
            this.root = root;
            this.token = properties.token
            this.DEBUG = properties.debug || false;
            this.help = properties.help || 'no.help.available@dev.null'

            _.bindAll(this, "fetchVersion", "rows", "records", "fetchTemplates",
                "fetchLists", "fetchList", "fetchListsContaining",
                "count", "makeRequest", "fetchModel", "fetchSummaryFields",
                "combineLists", "merge", "intersect", "diff", "query", "whoami", "findById",
                "post", "get");

        }, this);

        this.fetchVersion = function(cb) {
            var self = this;
            var promise = Deferred();
            if (cb == null) {
                cb = IDENTITY;
            }
            if (typeof this.version === "undefined") {
                this.makeRequest(VERSION_PATH, null, function(data) {
                    this.version = data.version;
                    cb(this.version);
                    promise.resolve(this.version);
                }).fail(promise.reject);
            } else {
                cb(this.version);
                promise.resolve(this.version);
            }
            return promise;
        };

        this.fetchTemplates = function(cb) {
            return this.makeRequest(TEMPLATES_PATH).pipe(getResultProcessor('templates')(cb));
        };


        var listProcessor = getResultProcessor('lists')();
        var instantiate_lists = function(lists) {
            return lists.map(function(l) { return new List(l, __service); });
        };
        var listFinder = function(name) { return function(lists) {
            var ret = Deferred(), l = _.find(lists, function(l) { return l.name === name });
            if (l == null) {
                ret.reject("List not found");
            } else {
                ret.resolve(l);
            }
            return ret.promise();
        }};

        this.fetchLists = function(cb) {
            return this.makeRequest(LISTS_PATH).pipe(listProcessor).pipe(instantiate_lists).done(cb);
        };

        this.fetchList = function(name, cb) {
            return this.fetchLists().pipe(listFinder(name)).then(cb, this.errorHandler);
        }

        this.combineLists = function(operation) {
            var self = this;
            return function(options, cb) {
                var path = LIST_OPERATION_PATHS[operation],
                    params = {
                        name: options.name,
                        tags: options.tags.join(';'),
                        lists: options.lists.join(";"),
                        description: options.description
                    };
                return self.get(path, params)
                    .pipe(getResultProcessor('listName')())
                    .pipe(self.fetchList)
                    .done(cb);
            };
        };

        this.merge = this.combineLists("merge");
        this.intersect = this.combineLists("intersect");
        this.diff = this.combineLists("diff");

        var getModeller = function(self) { return function(data) {
            var fn = ((Model && function(m) { return new Model(m); }) || IDENTITY);
            self.model = fn(data.model);
            self.model.service = self;
            return MODELS[self.root] = self.model;
        }};

        /**
         * A function that handles a data model.
         * @name ModelHandler
         * @param model {Model} The model to process.
         */

        /**
         * Fetch the definition of the data model from the server.
         *
         * @this {Service}
         * @param cb {ModelHandler} An optional model handling callback.
         * @return {Deferred} A promise to fetch the data-model.
         */
        this.fetchModel = function(cb) {
            if (!this.model && MODELS[this.root]) {
                this.model = MODELS[this.root];
            }
            if (this.model) {
                return Deferred().resolve(this.model).done(cb).promise();
            } else {
                return this.get(MODEL_PATH).pipe(getModeller(this)).done(cb);
            }
        };

        this.fetchSummaryFields = function(cb) {
            var self = this;
            var promise = Deferred();
            if (SUMMARY_FIELDS[self.root]) {
                self.summaryFields = SUMMARY_FIELDS[self.root];
            }
            if (self.summaryFields) {
                cb(self.summaryFields);
                promise.resolve(self.summaryFields);
            } else {
                self.makeRequest(SUMMARYFIELDS_PATH, null, function(data) {
                    self.summaryFields = data.classes;
                    SUMMARY_FIELDS[self.root] = data.classes;
                    cb(self.summaryFields);
                    promise.resolve(self.summaryFields);
                });
            }
            promise.fail(this.errorHandler);
            return promise;
        };

        /**
         * A request to fetch lists that contain an item by their internal ID.
         * @name InternalIDRequest
         * @property {number|string} The Internal ID (should be a valid Java Integer).
         */

        /**
         * A request to fetch lists containing an item by a stable external identifier.
         * @name PublicIdRequest
         * @property {!string} publicId The stable external unique identifier.
         * @property {!string} type The type of the object (eg: "Gene").
         * @property {?string} extraValue An optional extra value to help resolve the object.
         *                                (eg, for a Gene, the Organism name).
         */

        /**
        * Fetch lists containing an item.
        *
        * @param {InternalIDRequest | PublicIdRequest} options Options should contain: 
        * @param {function(Array.<List>)} an optional callback function.
        * @return {Deferred.<Model>} A promise to return a model
        */
        this.fetchListsContaining = function(opts, cb) {
            return this.get(WITH_OBJ_PATH, opts).pipe(listProcessor).done(cb);
        };

        /**
         * Construct a query, and yield it to the callback.
         * @param options The query defined in a JSON structure
         * @param cb The continuation of this function.
         * @return {Deffered} a promise to make a query.
         */
        this.query = function(options, cb) {
            var service = this;
            var promise = Deferred();
            service.fetchModel(function(m) {
                service.fetchSummaryFields(function(sfs) {
                    _.extend(options, {model: m, summaryFields: sfs});
                    var q;
                    try {
                        q = new Query(options, service);
                    } catch (e) {
                        promise.reject(e);
                    }
                    if (cb) {
                        try {
                            cb(q);
                        } catch (e) {
                            promise.reject(e);
                        }
                    }
                    promise.resolve(q);
                }).fail(promise.reject);
            }).fail(promise.reject);
            promise.fail(this.errorHandler);
            return promise;
        };

        this.manageUserPreferences = function(method, data) {
            var service = this;
            return this.fetchVersion().pipe(function(v) {
                if (v >= 11) {
                    return service.makeRequest("user/preferences", data, null, method)
                                  .pipe(function(resp) {return resp.preferences});
                } else {
                    return Deferred().reject('not available',
                        'This service does not provide preferences');
                }
            }, this.errorHandler);
        };

        constructor(properties || {});
    };

    exports.Service = Service;
    if (IS_NODE) {
        exports.Model = Model;
        exports.Query = Query;
        exports.List = List;
        exports.User = User;
    }
}).call(this, typeof exports === 'undefined' ? this : exports, typeof exports != 'undefined');

        

"use strict";

(function(exports, IS_NODE) {

    var Model, Query, List, _, Deferred;
    if (IS_NODE) {
        _ = require('underscore')._;
        Deferred = require('jquery-deferred').Deferred;
        var http     = require('http');
        var URL      = require('url');
        var qs       = require('querystring');
        Model        = require('./model').Model;
        Query        = require('./query').Query;
        List         = require('./lists').List;
        var EventEmitter = require('events').EventEmitter;
        var BufferedResponse = require('buffered-response').BufferedResponse;
    } else {
        _ = exports._;
        Deferred = exports.jQuery.Deferred;
        if (typeof exports.intermine === 'undefined') {
            exports.intermine = {};
        }
        exports = exports.intermine;
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

    var Service = function(properties) {

        if (typeof Model === 'undefined' && intermine) {
            Model = intermine.Model;
        }
        if (typeof Query === 'undefined' && intermine) {
            Query = intermine.Query;
        }
        if (typeof List === 'undefined' && intermine) {
            List = intermine.List;
        }

        var getResulteriser = function(cb) { return function(data) {
            cb = cb || function() {};
            cb(data.results, data);
        }};

        var getFormat = function(def) {
            var format = def || "json";
            if (!(IS_NODE || jQuery.support.cors)) {
                format = format.replace("json", "jsonp");
            }
            return format;
        };

        /**
        * Performs a get request for data against a url. 
        * This method makes use of jsonp where available.
        */
        this.makeRequest = function(path, data, cb, method, itemByItem) {
            var url   = this.root + path;
            var errorCB = this.errorHandler;
            data = data || {};
            cb = cb || function() {};
            if (this.token) {
                data.token = this.token;
            }
            var dataType = "json";
            data.format = getFormat(data.format);

            if (_(cb).isArray()) {
                errorCB = cb[1];
                cb = cb[0];
            }

            if (!(IS_NODE || jQuery.support.cors)) {
                data.method = method;
                method = false; 
                url += "?callback=?";
                dataType = "jsonp";
                console.log("No CORS support: going for jsonp");
            } else if (IS_NODE && !method) {
                method = "GET";
            }

            if (method) {
                if (method === "DELETE") {
                    // grumble grumble struts grumble grumble...
                    url += "?" + to_query_string(data);
                }
                return this.doReq({
                    data: data,
                    dataType: "json",
                    success: cb,
                    error: errorCB,
                    url: url,
                    type: method
                }, itemByItem);
            } else {
                return jQuery.getJSON(url, data, cb);
            }
        };

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
                             var e = new Error("Server reported error: " + container.error + ", " + container.statusCode);
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
                                var error = new Error("When running " + JSON.stringify(opts.data) + ": " + parsed.error);
                                ret.reject(error, parsed.status);
                            } else {
                                ret.resolve(parsed);
                            }
                        } catch(e) {
                            ret.reject(new Error("Could not parse buffer (" + contentBuffer + "): " + e));
                        }
                     } else {
                         var e;
                         if (e = contentBuffer.match(/\[Error\] (\d+)(.*)/m)) {
                             ret.reject(new Error(e[2], e[1]));
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
                url.headers = {'User-Agent': 'node-http/imjs'};
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
                return jQuery.ajax(opts);
            }
            var __wrap_cbs = function(cbs) {
                var wrappedSuccess, error;
                if (_.isArray(cbs)) {
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
                var _cbs = __wrap_cbs(cbs);
                page = page || {};
                var req = _(page).extend({query: q.toXML()});
                return this.makeRequest(QUERY_RESULTS_PATH, req, _cbs, 'POST');

            };
            this.recordByRecord = function(q, page, cbs) {
                var _cbs = __wrap_cbs(cbs);
                page = page || {};
                var req = _(page).extend({query: q.toXML(), format: "jsonobjects"});
                return this.makeRequest(QUERY_RESULTS_PATH, req, _cbs, 'POST');

            };
        }
        this.eachRow = this.rowByRow;
        this.eachRecord = this.recordByRecord;

        this.widgets = function(cb) {
            cb = cb || _.identity;
            return this.makeRequest(WIDGETS_PATH, null, function(data) {
                cb(data.widgets);
            });
        };

        this.enrichment = function(req, cb) {
            cb = cb || _.identity;
            _.defaults(req, {maxp: 0.05});
            return this.makeRequest(ENRICHMENT_PATH, req, function(data) {cb(data.results)});
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
            cb      = cb      || function() {};
            _.defaults(options, {term: "", facets: {}});
            var req = {q: options.term, start: options.start, size: options.size};
            if (options.facets) {
                _(options.facets).each(function(v, k) {
                    req["facet_" + k] = v;
                });
            }
            return this.makeRequest(QUICKSEARCH_PATH, req, function(data) {
                cb(data.results, data.facets);
            }, "POST");
        };

        this.count = function(q, cont) {
            var req = {
                query: q.toXML(),
                format: (IS_NODE || jQuery.support.cors) ? "jsoncount" : "jsonpcount"
            };
            var promise = Deferred();
            this.makeRequest(QUERY_RESULTS_PATH, req, function(data) {
                if (cont) 
                    cont(data.count);
                promise.resolve(data.count);
            }).fail(promise.reject);
            promise.fail(this.errorHandler);
            return promise;
        };

        this.findById = function(table, objId, cb) {
            this.query({from: table, select: ["**"], where: {"id": objId}}, function(q) {
                q.records(function(rs) {
                    cb(rs[0]);
                });
            });
        };

        this.whoami = function(cb) {
            cb = cb || function() {};
            var self = this;
            var promise = Deferred();
            self.fetchVersion(function(v) {
                if (v < 9) {
                    var msg = "The who-am-i service requires version 9, this is only version " + v;
                    promise.reject("not available", msg);
                } else {
                    self.makeRequest("user/whoami", null, function(resp) {cb(resp.user)})
                        .then(promise.resolve, promise.reject);
                }
            });
            return promise;
        };

        this.table = function(q, page, cb) {
            page = page || {};
            var req = _(page).extend({
                query: q.toXML(), 
                format: "jsondatatable"
            });
            return this.makeRequest(QUERY_RESULTS_PATH, req, getResulteriser(cb), "POST");
        };

        this.records = function(q, page, cb) {
            // Allow calling as records(q, cb)
            if (_(cb).isUndefined() && _(page).isFunction()) {
                cb = page;
                page = {};
            }
            page = page || {};
            var req = _(page).extend({query: q.toXML(), format: (IS_NODE || jQuery.support.cors) ? "jsonobjects" : "jsonpobjects"});
            return this.makeRequest(QUERY_RESULTS_PATH, req, getResulteriser(cb), 'POST');
        };

        this.rows = function(q, page, cb) {
            // Allow calling as rows(q, cb)
            if (_(cb).isUndefined() && _(page).isFunction()) {
                cb = page;
                page = {};
            }
            page = page || {};
            var req = _(page).extend({query: q.toXML()});
            return this.makeRequest(QUERY_RESULTS_PATH, req, getResulteriser(cb), 'POST');
        };

        this.tableRows = function(q, page, cb) {
            // Allow calling as records(q, cb)
            if (_(cb).isUndefined() && _(page).isFunction()) {
                cb = page;
                page = {};
            }
            page = page || {};
            var req = _(page).extend({query: q.toXML(), format: "json"});
            return this.makeRequest(QUERY_RESULTS_PATH + "/tablerows", req, getResulteriser(cb), 'POST');
        };


        var constructor = _.bind(function(properties) {
            var root = properties.root;
            if (root && !/^https?:\/\//i.test(root)) {
                root = DEFAULT_PROTOCOL + root;
            }
            if (root && !/service\/?$/i.test(root)) {
                root = root + "/service/";
            }
            if (properties.errorHandler) {
                this.errorHandler = properties.errorHandler;
            } else {
                this.errorHandler = function(err, text) {
                    console.log(err);
                    if (text) {
                        console.log(text);
                    }
                    console.log(err.stack ? err.stack : "");
                };
            }
            this.root = root;
            this.token = properties.token
            this.DEBUG = properties.debug || false;
            this.help = properties.help || 'no.help.available@dev.null'

            _.bindAll(this, "fetchVersion", "rows", "records", "fetchTemplates", "fetchLists", 
                "count", "makeRequest", "fetchModel", "fetchSummaryFields", "combineLists", 
                "merge", "intersect", "diff", "query", "whoami");

        }, this);

        this.fetchVersion = function(cb) {
            var self = this;
            var promise = Deferred();
            if (typeof this.version === "undefined") {
                this.makeRequest(VERSION_PATH, null, function(data) {
                    this.version = data.version;
                    cb(this.version);
                }).fail(promise.reject);
            } else {
                cb(this.version);
                promise.resolve(this.version);
            }
            return promise;
        };

        this.fetchTemplates = function(cb) {
            var promise = Deferred();
            this.makeRequest(TEMPLATES_PATH, null, function(data) {
                cb(data.templates);
                promise.resolve(data.templates);
            }).fail(promise.reject);
            promise.fail(this.errorHandler);
            return promise;
        };

        this.fetchLists = function(cb) {
            var self = this;
            var promise = Deferred();
            this.makeRequest(LISTS_PATH, null, function(data) {
                var lists = _(data.lists).map(function (l) {return new List(l, self)});
                cb(lists);
                promise.resolve(lists);
            }).fail(promise.reject);
            promise.fail(this.errorHandler);
            return promise;
        };

        this.combineLists = function(operation) {
            var self = this;
            return function(options, cb) {
                var promise = Deferred();
                var path = LIST_OPERATION_PATHS[operation];
                var params = {
                    name: options.name,
                    tags: options.tags.join(';'),
                    lists: options.lists.join(";"),
                    description: options.description
                };
                self.makeRequest(path, params, function(data) {
                    var name = data.listName;
                    self.fetchLists(function(ls) {
                        var l = _(ls).find(function(l) {return l.name === name});
                        cb(l);
                        promise.resolve(l);
                    }).fail(promise.reject);
                }).fail(promise.reject);
                promise.fail(self.errorHandler);
                return promise;
            };
        };

        this.merge = this.combineLists("merge");
        this.intersect = this.combineLists("intersect");
        this.diff = this.combineLists("diff");

        this.fetchModel = function(cb) {
            var self = this;
            var promise = Deferred();
            if (MODELS[self.root]) {
                self.model = MODELS[self.root];
            }
            if (self.model) {
                cb(self.model);
                promise.resolve(self.model);
            } else {
                this.makeRequest(MODEL_PATH, null, function(data) {
                    if (Model) {
                        self.model = new Model(data.model);
                    } else {
                        self.model = data.model;
                    }
                    self.model.service = self;
                    MODELS[self.root] = self.model;
                    cb(self.model);
                    promise.resolve(self.model);
                }).fail(promise.reject);
            }
            return promise;
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
        * Fetch lists containing an item.
        *
        * @param options Options should contain: 
        *  - either:
        *    * id: The internal id of the object in question
        *  - or: 
        *    * publicId: An identifier
        *    * type: The type of object (eg. "Gene")
        *    * extraValue: (optional) A domain to help resolve the object (eg an organism for a gene).
        *
        *  @param cb function of the type: [List] -> ()
        *  @return A promise
        */
        this.fetchListsContaining = function(opts, cb) {
            cb = cb || function() {};
            return this.makeRequest(WITH_OBJ_PATH, opts, function(data) {cb(data.lists)});
        };


        this.query = function(options, cb) {
            var service = this;
            var promise = Deferred();
            service.fetchModel(function(m) {
                service.fetchSummaryFields(function(sfs) {
                    _.defaults(options, {model: m, summaryFields: sfs});
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

        constructor(properties || {});
    };

    exports.Service = Service;
    if (IS_NODE) {
        exports.Model = Model;
        exports.Query = Query;
        exports.List = List;
    }
}).call(this, typeof exports === 'undefined' ? this : exports, typeof exports != 'undefined');

        

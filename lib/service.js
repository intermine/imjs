(function(globals) {
    exports = exports || globals;
    if (globals && typeof exports.intermine == 'undefined') {
        exports.intermine = {};
        exports = intermine;
    }

    var IS_NODE  = true;
    if (globals && globals.jQuery) {
        IS_NODE = false;
    }

    var Model;
    var Query;
    var List;
    if (IS_NODE) {
        var _        = require('underscore')._;
        var Deferred = require('jquery-deferred').Deferred;
        var http     = require('http');
        var URL      = require('url');
        var qs       = require('querystring');
        Model        = require('./model').Model;
        Query        = require('./query').Query;
        List         = require('./lists').List;
        var EventEmitter = require('events').EventEmitter;
        var BufferedResponse = require('buffered-response').BufferedResponse;
    }

    var __ = function(x) {return _(x).chain()};

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
        if (typeof Query === 'undefined' && intermine) {
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
            var errorCB = function() {};
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

            this.doReq = function(opts, resultByResult) {
                var ret = resultByResult ? new EventEmitter() : new Deferred();
                var contentBuffer = "";
                var containerBuffer = "";
                var postdata = to_query_string(opts.data);
                if (resultByResult) {
                    ret.on('item', opts.success);
                    ret.on('error', opts.error);
                    ret.fail = function() {ret.emit.apply(ret, 
                        ['error', Array.prototype.slice.call(arguments, 0)])};
                } else {
                    ret.done(opts.success);
                }
                var url = URL.parse(opts.url, true);
                url.method = opts.type;
                url.port = url.port || 80;
                if (url.method === 'GET' && _(opts.data).size()) {
                    url.path += "?" + postdata;
                } else if (url.method === 'POST') {
                    url.headers = {
                        'Content-Type': 'application/x-www-form-urlencoded',
                        'Content-Length': postdata.length
                    };
                }
                var peskyComma = /,\s*$/;
                var req = http.request(url, function(res) {
                    if (resultByResult) {
                        var reader = new BufferedResponse(res);
                        reader.setEncoding('utf8');
                        reader.on('line', function(line) {
                            if (line[0] === ']' || line[line.length - 1] === '[') {
                                containerBuffer += line;
                            } else {
                                try {
                                    var parsed = JSON.parse(line.replace(peskyComma, ''));
                                    ret.emit('item', parsed);
                                } catch(e) {
                                    ret.emit('error', e, line);
                                }
                            }
                        });
                        reader.on('end', function() {
                            try {
                                var container = JSON.parse(containerBuffer);
                                if (container.error) {
                                    ret.emit('error', container.error);
                                }
                            } catch (e) {
                                ret.emit('error', e, containerBuffer);
                            }
                            ret.emit('end');
                        });
                    } else {
                       res.on('data', function(chunk) {contentBuffer += chunk});
                       res.on('end', function() {
                           var parsed;
                           try {
                               parsed = JSON.parse(contentBuffer);
                               if (parsed.error) {
                                   ret.fail(parsed.error, parsed.status);
                               } else {
                                   ret.resolve(parsed);
                               }
                           } catch(e) {
                               ret.fail(e, contentBuffer);
                           }
                       });
                    }
                });

                req.on('error', function(e) {
                    ret.fail(e);
                });

                if (url.method === 'POST') {
                    req.write(postdata);
                }
                req.end();
                return ret;
            };
        } else {
            this.doReq = function(opts) {
                return jQuery.ajax(opts);
            }
        }

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
                cont(data.count);
                promise.resolve(data.count);
            }).fail(promise.reject);
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

        var constructor = _.bind(function(properties) {
            var root = properties.root;
            if (root && !/^https?:\/\//i.test(root)) {
                root = DEFAULT_PROTOCOL + root;
            }
            if (root && !/service\/?$/i.test(root)) {
                root = root + "/service/";
            }
            this.root = root;
            this.token = properties.token

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
                    var q = new Query(options, service);
                    cb(q);
                    promise.resolve(q);
                }).fail(promise.reject);
            }).fail(promise.reject);
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
}).call(this);

        

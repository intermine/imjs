if (typeof intermine == "undefined") {
    intermine = {};
}

if (typeof __ == "undefined") {
    __ = function(x) {return _(x).chain()};
}

_.extend(intermine, (function() {

    var MODELS = {};
    var SUMMARY_FIELDS = {};

    var Service = function(properties) {
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

        var LIST_OPERATION_PATHS = {
            merge: "lists/union",
            intersect: "lists/intersect",
            diff: "lists/diff"
        };

        /**
         * Performs a get request for data against a url. 
         * This method makes use of jsonp where available.
         */
        this.makeRequest = function(path, data, cb, method) {
            var url = this.root + path;
            data = data || {};
            cb = cb || function() {};
            if (this.token) {
                data.token = this.token;
            }
            if (!data.format) {
                if (jQuery.support.cors) {
                    data.format = "json";
                } else {
                    method = false; // Can't
                    data.format = "jsonp";
                }
            }
            if (method) {
                if (method === "DELETE") {
                    // grumble grumble struts grumble grumble...
                    url += "?" + jQuery.param(data);
                }
                return jQuery.ajax({
                    data: data,
                    dataType: "json",
                    success: cb,
                    url: url,
                    type: method
                });
            } else {
                return jQuery.getJSON(url, data, cb);
            }
        };

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
                format: jQuery.support.cors ? "jsoncount" : "jsonpcount",
            };
            return this.makeRequest(QUERY_RESULTS_PATH, req, function(data) {
                cont(data.count);
            });
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
            var promise = jQuery.Deferred();
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

        this.records = function(q, page, cb) {
            // Allow calling as records(q, cb)
            if (_(cb).isUndefined() && _(page).isFunction()) {
                cb = page;
                page = {};
            }
            cb = cb || function() {};
            page = page || {};
            var req = _(page).extend({query: q.toXML(), format: jQuery.support.cors ? "jsonobjects" : "jsonpobjects"});
            return this.makeRequest(QUERY_RESULTS_PATH, req, function(data) {
                cb(data.results);
            });
        };

        this.rows = function(q, page, cb) {
            // Allow calling as rows(q, cb)
            if (_(cb).isUndefined() && _(page).isFunction()) {
                cb = page;
                page = {};
            }
            page = page || {};
            var req = _(page).extend({query: q.toXML()});
            this.makeRequest(QUERY_RESULTS_PATH, req, function(data) {
                cb(data.results);
            });
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
            var promise = jQuery.Deferred();
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
            this.makeRequest(TEMPLATES_PATH, null, function(data) {
                cb(data.templates);
            });
        };

        this.fetchLists = function(cb) {
            var self = this;
            this.makeRequest(LISTS_PATH, null, function(data) {
                cb(_(data.lists).map(function (l) {return new intermine.List(l, self)}));
            });
        };

        this.combineLists = function(operation) {
            var self = this;
            return function(options, cb) {
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
                        cb(_(ls).find(function(l) {return l.name === name}));
                    });
                });
            };
        };

        this.merge = this.combineLists("merge");
        this.intersect = this.combineLists("intersect");
        this.diff = this.combineLists("diff");

        this.fetchModel = function(cb) {
            var self = this;
            if (MODELS[self.root]) {
                self.model = MODELS[self.root];
            }
            if (self.model) {
                cb(self.model);
            } else {
                this.makeRequest(MODEL_PATH, null, function(data) {
                    if (intermine.Model) {
                        self.model = new intermine.Model(data.model);
                    } else {
                        self.model = data.model;
                    }
                    MODELS[self.root] = self.model;
                    cb(self.model);
                });
            }
        };

        this.fetchSummaryFields = function(cb) {
            var self = this;
            if (SUMMARY_FIELDS[self.root]) {
                self.summaryFields = SUMMARY_FIELDS[self.root];
            }
            if (self.summaryFields) {
                cb(self.summaryFields);
            } else {
                self.makeRequest(SUMMARYFIELDS_PATH, null, function(data) {
                    self.summaryFields = data.classes;
                    SUMMARY_FIELDS[self.root] = data.classes;
                    cb(self.summaryFields);
                });
            }
        };

        this.query = function(options, cb) {
            var service = this;
            service.fetchModel(function(m) {
                service.fetchSummaryFields(function(sfs) {
                    _.defaults(options, {model: m, summaryFields: sfs});
                    cb(new intermine.Query(options, service));
                });
            });
        };

        constructor(properties || {});
    };

    return {"Service": Service};
})());

        

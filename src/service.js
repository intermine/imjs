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

        this.makeRequest = _.bind(function(path, data, cb) {
            var url = this.root + path;
            data = data || {};
            if (this.token) {
                data.token = this.token;
            }
            if (!data.format) {
                if (jQuery.support.cors) {
                    data.format = "json";
                } else {
                    data.format = "jsonp";
                }
            }
            jQuery.getJSON(url, data, cb);
        }, this);

        this.count = function(q, cont) {
            var req = {
                query: q.toXML(),
                format: jQuery.support.cors ? "jsoncount" : "jsonpcount",
            };
            this.makeRequest(QUERY_RESULTS_PATH, req, function(data) {
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

        this.records = function(q, page, cb) {
            // Allow calling as rows(q, cb)
            if (_(cb).isUndefined() && _(page).isFunction()) {
                cb = page;
                page = {};
            }
            page = page || {};
            var req = _(page).extend({query: q.toXML(), format: jQuery.support.cors ? "jsonobjects" : "jsonpobjects"});
            this.makeRequest(QUERY_RESULTS_PATH, req, function(data) {
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

        }, this);

        this.fetchVersion = _.bind(function(cb) {
            if (typeof this.version === "undefined") {
                this.makeRequest(VERSION_PATH, null, _.bind(function(data) {
                    this.version = data.version;
                    cb(this.version);
                }, this));
            } else {
                cb(this.version);
            }
        }, this);

        this.fetchTemplates = _.bind(function(cb) {
            this.makeRequest(TEMPLATES_PATH, null, function(data) {
                cb(data.templates);
            });
        }, this);

        this.fetchLists = _.bind(function(cb) {
            this.makeRequest(LISTS_PATH, null, _(function(data) {
                cb(_(data.lists).map(function (l) {return new intermine.List(l, this)}));
            }).bind(this));
        }, this);

        this.fetchModel = _.bind(function(cb) {
            if (MODELS[this.root]) {
                this.model = MODELS[this.root];
            }
            if (this.model) {
                cb(this.model);
            } else {
                this.makeRequest(MODEL_PATH, null, _.bind(function(data) {
                    if (intermine.Model) {
                        this.model = new intermine.Model(data.model);
                    } else {
                        this.model = data.model;
                    }
                    MODELS[this.root] = this.model;
                    cb(this.model);
                }, this));
            }
        }, this);

        this.fetchSummaryFields = function(cb) {
            if (SUMMARY_FIELDS[this.root]) {
                this.summaryFields = SUMMARY_FIELDS[this.root];
            }
            if (this.summaryFields) {
                cb(this.summaryFields);
            } else {
                this.makeRequest(SUMMARYFIELDS_PATH, null, _.bind(function(data) {
                    this.summaryFields = data.classes;
                    SUMMARY_FIELDS[this.root] = data.classes;
                    cb(this.summaryFields);
                }, this));
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

        

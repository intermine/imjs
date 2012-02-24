if (typeof intermine == "undefined") {
    intermine = {};
}
if (typeof __ == "undefined") {
    __ = function(x) {return _(x).chain()};
}

_.extend(intermine, (function() {
    var Query = function(properties, service) {
        
        var adjustPath, constructor;

        var JOIN_STYLES = ["INNER", "OUTER"];
        var NULL_OPS = ["IS NULL", "IS NOT NULL"];
        var OP_DICT  = {
            "=" : "=",
            "==": "=",
            "eq": "=",
            "!=": "!=",
            "ne": "!=",
            ">" : ">",
            "gt" : ">",
            ">=": ">=",
            "ge": ">=",
            "<": "<",
            "lt": "<",
            "<=": "<=",
            "le": "<=",
            "contains": "CONTAINS",
            "like": "LIKE", 
            "lookup": "LOOKUP",
            "IS NULL": "IS NULL",
            "is null": "IS NULL",
            "IS NOT NULL": "IS NOT NULL",
            "is not null": "IS NOT NULL",
            "ONE OF": "ONE OF",
            "one of": "ONE OF",
            "in": "IN",
            "not in": "IN",
            "IN": "IN",
            "NOT IN": "NOT IN"
        };

        /**
         * Allow others to listed to events on this query.
         *
         * Straight copy of Backbone events.
         */
        this.on = function(events, callback, context) {
            var ev;
            events = events.split(/\s+/);
            var calls = this._callbacks || (this._callbacks = {});
            while (ev = events.shift()) {
                var list = calls[ev] || (calls[ev] = {});
                var tail = list.tail || (list.tail = list.next = {});
                tail.callback = callback;
                tail.context = context;
                list.tail = tail.next = {};
            }

            return this;
        }
        
        this.bind = this.on;

        // Trigger an event, firing all bound callbacks. Callbacks are passed the
        // same arguments as `trigger` is, apart from the event name.
        // Listening for `"all"` passes the true event name as the first argument.
        this.trigger = function(events) {
            var event, node, calls, tail, args, all, rest;
            if (!(calls = this._callbacks)) return this;
            all = calls['all'];
            (events = events.split(/\s+/)).push(null);
            // Save references to the current heads & tails.
            while (event = events.shift()) {
                if (all) events.push({next: all.next, tail: all.tail, event: event});
                if (!(node = calls[event])) continue;
                events.push({next: node.next, tail: node.tail});
            }
            // Traverse each list, stopping when the saved tail is reached.
            rest = slice.call(arguments, 1);
            while (node = events.pop()) {
                tail = node.tail;
                args = node.event ? [node.event].concat(rest) : rest;
                while ((node = node.next) !== tail) {
                node.callback.apply(node.context || this, args);
                }
            }
            return this;
        };

        var get_canonical_op = function(orig) {
            var canonical = _(orig).isString() ? OP_DICT[orig.toLowerCase()] : null;
            if (canonical == null) {
                throw "Illegal constraint operator: " + orig;
            }
            return canonical;
        }

        constructor = _.bind(function(properties, service) {
            _.defaults(this, {
                constraints: [], 
                views: [], 
                joins: [], 
                constraintLogic: "",
                sortOrder: []
            });
            this.service = service || {};
            this.model = properties.model || {};
            this.summaryFields = properties.summaryFields || {};
            this.root = properties.root || properties.from;
            this.select(properties.views || properties.select || []);
            this.addConstraints(properties.constraints || properties.where || []);
            this.addJoins(properties.joins || properties.join || []);
            this.constraintLogic = properties.constraintLogic || this.constraintLogic;
            this.orderBy(properties.sortOrder || properties.orderBy || []);
            this.maxRows = properties.size || properties.limit;
            this.start = properties.start || properties.offset || 0;
        }, this);


        this.addToSelect = function(views) {
            var self = this;
            __(views).map(_(adjustPath).bind(this))
                     .map(_(expandStar).bind(this))
                     .flatten()
                     .each(function(p) { self.views.push(p) });
            return this;
        };

        this.select = function(views) {
            this.views = [];
            this.addToSelect(views);
            return this;
        };

        var adjustPath = function(path) {
            if (path.indexOf(this.root) != 0) {
                path = this.root + "." + path;
            }
            return path;
        };

        var expandStar = function(path) {
            if (/\*$/.test(path)) {
                var pathStem = path.substr(0, path.lastIndexOf("."));
                var expand = function(x) {return pathStem + x};
                var cd = this.model.getCdForPath(pathStem);
                if (/\.\*$/.test(path)) {
                    if (cd && this.summaryFields[cd.name]) {
                        var decapitate = function(x) {return x.substr(x.indexOf("."))};
                        return _(this.summaryFields[cd.name]).map(_.compose(expand, decapitate))
                    }
                } 
                if (/\.\*\*$/.test(path)) {
                    var str = function(a) {return "." + a.name};
                    return __(_(expandStar).bind(this)(pathStem + ".*"))
                            .union(_(cd.attributes).map(_.compose(expand, str)))
                            .unique()
                            .value();
                } 
            }
            return path;
        }

        this.count = function(cont) {
            if (this.service.count) {
                this.service.count(this, cont);
            } else {
                throw "This query has no service. It cannot request a count";
            }
        };

        this.saveAsList = function(options, cb) {
            var toRun  = this.clone();
            cb = cb || function() {};
            toRun.select(["id"]);
            var req = _.clone(options);
            req.listName = req.listName || req.name;
            req.query = toRun.toXML();
            if (options.tags) {
                req.tags = options.tags.join(';');
            }
            var service = this.service;
            return service.makeRequest("query/tolist", req, function(data) {
                var name = data.listName;
                service.fetchLists(function(ls) {
                    cb(_(ls).find(function(l) {return l.name === name}));
                });
            }, "POST");
        };

        this.summarise = function(path, limit, cont) {
            if (_.isFunction(limit) && !cont) {
                cont = limit;
                limit = null;
            };
            cont = cont || function() {};
            path = adjustPath.call(this, path);
            var toRun = this.clone();
            if (!_(toRun.views).include(path)) {
                toRun.views.push(path);
            }
            var req = {query: toRun.toXML(), format: "jsonrows", summaryPath: path};
            if (limit) {
                req.size = limit;
            }
            return this.service.makeRequest("query/results", req, function(data) {cont(data.results, data.uniqueValues)});
        };

        this.summarize = this.summarise;

        this._get_data_fetcher = function(serv_fn) { 
            return function(page, cb) {
                var self = this;
                cb = cb || page;
                page = (_(page).isFunction() || !page) ? {} : page;
                if (self.service[serv_fn]) {
                    _.defaults(page, {start: self.start, size: self.maxRows});
                    return self.service[serv_fn](self, page, cb);
                } else {
                    throw "This query has no service. It cannot request results";
                }
            };
        };

        this.records = this._get_data_fetcher("records");
        this.rows = this._get_data_fetcher("rows");
        this.table = this._get_data_fetcher("table");

        this.clone = function() {
            // Not the fastest, but it does make isolated clones.
            return jQuery.extend(true, {}, this);
        };

        this.next = function() {
            var clone = this.clone();
            if (this.maxRows) {
                clone.start = this.start + this.maxRows;
            }
            return clone;
        };

        this.previous = function() {
            var clone = this.clone();
            if (this.maxRows) {
                clone.start = this.start - this.maxRows;
            } else {
                clone.start = 0;
            }
            return clone;
        };

        /**
         * @triggers a "add:sortorder" event.
         */
        this.addSortOrder = function(so) {
            var adjuster = _(adjustPath).bind(this);
            if (_.isString(so)) {
                so = {path: so, direction: "ASC"};
            } else if (! so.path) {
                var k = _.keys(so)[0];
                var v = _.values(so)[0];
                so = {path: k, direction: v};
            }
            so.path = adjuster(so.path);
            so.direction = so.direction.toUpperCase();
            this.sortOrder.push(so);
            this.trigger("add:sortorder", so);
        };

        /**
         * @triggers a "set:sortorder" event.
         */
        this.orderBy = function(sort_orders) {
            this.sortOrder = [];
            _(sort_orders).each(_(this.addSortOrder).bind(this));
            this.trigger("set:sortorder", this.sortOrder);
            return this;
        };

        this.addJoins = function(joins) {
            _(joins).each(_(this.addJoin).bind(this));
            return this;
        };

        this.addJoin = function(join) {
            if (_.isString(join)) {
                join = {path: join, style: "OUTER"};
            }
            join.path = _(adjustPath).bind(this)(join.path);
            join.style = join.style ? join.style.toUpperCase() : join.style;
            if (!_(JOIN_STYLES).include(join.style)) {
                throw "Invalid join style: " + join.style;
            }
            this.joins.push(join);
            return this;
        };

        this.addConstraints = function(constraints) {
            if (_.isArray(constraints)) {
                _(constraints).each(_(this.addConstraint).bind(this));
            } else {
                var that = this;
                _(constraints).each(function(val, key) {
                    var constraint = {path: key};
                    if (_.isArray(val)) {
                        constraint.op = "ONE OF";
                        constraint.values = val;
                    } else if (_.isString(val) || _.isNumber(val)) {
                        if (_.isString(val) && _(NULL_OPS).include(val.toUpperCase())) {
                            constraint.op = val;
                        } else {
                            constraint.op = "=";
                            constraint.value = val;
                        }
                    } else {
                        var k = _.keys(val)[0];
                        var v = _.values(val)[0];
                        if (k == "isa") {
                            constraint.type = v;
                        } else {
                            constraint.op = k;
                            constraint.value = v;
                        }
                    }
                    that.addConstraint(constraint);
                });
            }
            return this;
        };

        /**
         * Triggers an "add:constraint" event.
         */
        this.addConstraint = function(constraint) {
            var that = this;
            if (_.isArray(constraint)) {
                var conArgs = constraint;
                var constraint = {path: conArgs.shift()};
                if (conArgs.length == 1) {
                    if (_(NULL_OPS).include(conArgs[0].toUpperCase())) {
                        constraint.op = conArgs[0];
                    } else {
                        constraint.type = conArgs[0];
                    }
                } else if (conArgs.length >= 2) {
                    constraint.op = conArgs[0];
                    var v = conArgs[1];
                    if (_.isArray(v)) {
                        constraint.values = v;
                    } else {
                        constraint.value = v;
                    }
                    if (conArgs.length == 3) {
                        constraint.extraValue = conArgs[2];
                    }
                }
            }

            constraint.path = _(adjustPath).bind(this)(constraint.path);
            if (!constraint.type) {
                try {
                    constraint.op = get_canonical_op(constraint.op);
                } catch(er) {
                    throw "Could not make constraint on " + constraint.path + ": " + er;
                }
            }
            this.constraints.push(constraint);
            this.trigger("add:constraint", constraint);
            return this;
        };

        this.getSorting = function() {
            return _(this.sortOrder).map(function(x) {return x.path + " " + x.direction}).join(" ");
        };

        this.getConstraintXML = function() {
            var xml = "";
            __(this.constraints).filter(function(c) {return c.type != null}).each(function(c) {
                xml += '<constraint path="' + c.path + '" type="' + c.type + '"/>';
            });
            __(this.constraints).filter(function(c) {return c.type == null}).each(function(c) {
                xml += '<constraint path="' + c.path + '" op="' + _.escape(c.op) + '"';
                if (c.value) {
                    xml += ' value="' + _.escape(c.value) + '"';
                }
                if (c.values) {
                    xml += '>';
                    _(c.values).each(function(v) {xml += '<value>' + _.escape(v) + '</value>'});
                    xml += '</constraint>';
                } else {
                    xml += '/>';
                }
            });
            return xml;
        };

        this.toXML = function() {
            var xml = "<query ";
            xml += 'model="' + this.model.name + '"';
            xml += ' ';
            xml += 'view="' + this.views.join(" ") + '"';
            if (this.sortOrder.length) {
                xml += ' sortOrder="' + this.getSorting() + '"';
            }
            if (this.constraintLogic) {
                xml += ' constraintLogic="' + this.constraintLogic + '"';
            }
            xml += ">";
            _(this.joins).each(function(j) {
                xml += '<join path="' + j.path + '" style="' + j.style + '"/>';
            });
            xml += this.getConstraintXML();
            xml += '</query>';

            return xml;
        };

        constructor(properties || {}, service);
    };
    return {"Query": Query};
})());

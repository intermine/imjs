/*! imjs - v2.0.2 - 2013-02-17 */

/**
This library is open source software according to the definition of the
GNU Lesser General Public Licence, Version 3, (LGPLv3) a copy of which is
included with this software. All use of this software is covered according to
the terms of the LGPLv3.

The copyright is held by InterMine (www.intermine.org) and Alex Kalderimis (alex@intermine.org).

Thu Jun 14 13:18:14 BST 2012
**/

(function(root) {
  if (typeof jQuery === 'undefined') {
    return null; 
  }
  var $ = jQuery;
  // jQuery.XDomainRequest.js
  // Author: Jason Moon - @JSONMOON
  // IE8+
  // see: https://github.com/MoonScript/jQuery-ajaxTransport-XDomainRequest
  if (!$.support.cors && window.XDomainRequest) {
    var httpRegEx = /^https?:\/\//i;
    var getOrPostRegEx = /^get|post$/i;
    var sameSchemeRegEx = new RegExp('^'+location.protocol, 'i');
    var jsonRegEx = /\/json/i;
    var xmlRegEx = /\/xml/i;

    var XDomainTransporter = function (userOptions, options) {
      this.userOptions = userOptions;
      this.options = options;
      this.userType = (userOptions.dataType||'').toLowerCase();
      _.bindAll(this);
    };
    XDomainTransporter.prototype.constructor = XDomainTransporter;
    XDomainTransporter.prototype.send = function(headers, complete) {
      this.xdr = new XDomainRequest();
      this.complete = complete;
      var xdr = this.xdr;
      if (/^\d+$/.test(this.userOptions.timeout)) {
        xdr.timeout = this.userOptions.timeout;
      }
      xdr.ontimeout = function() {
        complete(500, 'timeout');
      };
      xdr.onerror = function() {
        complete(500, 'error', { text: xdr.responseText });
      };
      xdr.onload = this.onLoad;
      var postData = (this.userOptions.data && $.param(this.userOptions.data)) || '';
      xdr.open(this.options.type, this.options.url);
      xdr.send(postData);
    };
    XDomainTransporter.prototype.abort = function() {
      if (xdr) {
        xdr.abort();
      }
    };
    XDomainTransporter.prototype.onLoad = function() {
      var xdr = this.xdr;
      var allResponseHeaders = 'Content-Length: ' + xdr.responseText.length + '\r\nContent-Type: ' + xdr.contentType;
      var status = {code: 200, message: 'success'};
      var responses = {text: xdr.responseText};
      try {
        if ((this.userType === 'json') || ((this.userType !== 'text') && jsonRegEx.test(xdr.contentType))) {
          try {
            responses.json = $.parseJSON(xdr.responseText);
          } catch (e) {
            status.code = 500;
            status.message = 'parseerror';
          }
        } else if ((this.userType === 'xml') || ((this.userType !== 'text') && xmlRegEx.test(xdr.contentType))) {
          var doc = new ActiveXObject('Microsoft.XMLDOM');
          doc.async = false;
          try {
            doc.loadXML(xdr.responseText);
          } catch(e) {
            doc = undefined;
          }
          if (!doc || !doc.documentElement || doc.getElementsByTagName('parsererror').length) {
            status.code = 500;
            status.message = 'parseerror';
            throw 'Invalid XML: ' + xdr.responseText;
          }
          responses.xml = doc;
        }
      } catch (parseMessage) {
        throw parseMessage;
      } finally {
        this.complete(status.code, status.message, responses, allResponseHeaders);
      }
    };

    // ajaxTransport exists in jQuery 1.5+
    jQuery.ajaxTransport('text html xml json', function(options, userOptions, jqXHR){
      // XDomainRequests must be: asynchronous, GET or POST methods, HTTP or HTTPS protocol, and same scheme as calling page
      if (options.crossDomain && options.async && getOrPostRegEx.test(options.type) && httpRegEx.test(userOptions.url) && sameSchemeRegEx.test(userOptions.url)) {
        return new XDomainTransporter(userOptions, options);
      }
    });
    $.support.cors = true;
  }
}).call(this, typeof exports === 'undefined' ? this : exports);

(function() {
  var IS_NODE, data, fs, imjs, intermine, path, pkg, _ref, _ref1;

  IS_NODE = typeof exports !== 'undefined';

  if (IS_NODE) {
    imjs = exports;
  } else {
    intermine = ((_ref = this.intermine) != null ? _ref : this.intermine = {});
    imjs = ((_ref1 = intermine.imjs) != null ? _ref1 : intermine.imjs = {});
  }

  imjs.VERSION = "unknown";

  if (IS_NODE) {
    fs = require('fs');
    path = require('path');
    if (process.mainModule != null) {
      data = fs.readFileSync(path.join(__dirname, '..', 'package.json'), 'utf8');
      pkg = JSON.parse(data);
      imjs.VERSION = pkg.version;
    }
  } else {
    imjs.VERSION = "2.0.2";
  }

}).call(this);

(function() {
  var IS_NODE, constants, intermine, _ref, _ref1;

  IS_NODE = typeof exports !== 'undefined';

  if (IS_NODE) {
    constants = exports;
  } else {
    intermine = ((_ref = this.intermine) != null ? _ref : this.intermine = {});
    constants = ((_ref1 = intermine.constants) != null ? _ref1 : intermine.constants = {});
  }

  constants.ACCEPT_HEADER = {
    'json': 'application/json',
    'jsonobjects': 'application/json;type=objects',
    'jsontable': 'application/json;type=table',
    'jsonrows': 'application/json;type=rows',
    'jsoncount': 'application/json;type=count',
    'jsonp': 'application/javascript',
    'jsonpobjects': 'application/javascript;type=objects',
    'jsonptable': 'application/javascript;type=table',
    'jsonprows': 'application/javascript;type=rows',
    'jsonpcount': 'application/javascript;type=count'
  };

}).call(this);

(function() {
  var IS_NODE, _base, _base1, _base2, _ref, _ref1, _ref2, _ref3;

  IS_NODE = typeof exports !== 'undefined';

  if (!IS_NODE) {
    if (Array.prototype.map == null) {
      Array.prototype.map = function(f) {
        var x, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = this.length; _i < _len; _i++) {
          x = this[_i];
          _results.push(f(x));
        }
        return _results;
      };
    }
    if (Array.prototype.filter == null) {
      Array.prototype.filter = function(f) {
        var x, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = this.length; _i < _len; _i++) {
          x = this[_i];
          if (f(x)) {
            _results.push(x);
          }
        }
        return _results;
      };
    }
    if (Array.prototype.reduce == null) {
      Array.prototype.reduce = function(f, initValue) {
        var ret, x, xs, _i, _len;
        xs = this.slice();
        ret = arguments.length < 2 ? xs.pop() : initValue;
        for (_i = 0, _len = xs.length; _i < _len; _i++) {
          x = xs[_i];
          ret = f(ret, x);
        }
        return ret;
      };
    }
    if (Array.prototype.forEach == null) {
      Array.prototype.forEach = function(f, ctx) {
        var i, x, _i, _len, _results;
        if (!f) {
          throw new Error("No function provided");
        }
        _results = [];
        for (i = _i = 0, _len = this.length; _i < _len; i = ++_i) {
          x = this[i];
          _results.push(f.call(ctx != null ? ctx : this, x, i, this));
        }
        return _results;
      };
    }
    if ((_ref = this.console) == null) {
      this.console = {
        log: (function() {}),
        error: (function() {}),
        debug: (function() {})
      };
    }
    if ((_ref1 = (_base = this.console).log) == null) {
      _base.log = function() {};
    }
    if ((_ref2 = (_base1 = this.console).error) == null) {
      _base1.error = function() {};
    }
    if ((_ref3 = (_base2 = this.console).debug) == null) {
      _base2.debug = function() {};
    }
  }

}).call(this);

(function() {
  var Deferred, IS_NODE, REQUIRES, fold, id, root, success, _, _base, _ref, _ref1,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty;

  IS_NODE = typeof exports !== 'undefined';

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  if (IS_NODE) {
    Deferred = require('underscore.deferred').Deferred;
    _ = require('underscore')._;
  } else {
    Deferred = root.jQuery.Deferred;
    _ = root._;
    if ((_ref = root.intermine) == null) {
      root.intermine = {};
    }
    if ((_ref1 = (_base = root.intermine).funcutils) == null) {
      _base.funcutils = {};
    }
    root = root.intermine.funcutils;
  }

  root.curry = function() {
    var args, f;
    f = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return function() {
      var rest;
      rest = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return f.apply(null, args.concat(rest));
    };
  };

  root.error = function(e) {
    return Deferred(function() {
      return this.reject(new Error(e));
    }).promise();
  };

  root.success = success = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return Deferred(function() {
      return this.resolve.apply(this, args);
    }).promise();
  };

  root.fold = fold = function(init, f) {
    return function(xs) {
      var k, ret, v;
      if (xs.reduce != null) {
        return xs.reduce(f, init);
      } else {
        ret = init;
        for (k in xs) {
          v = xs[k];
          ret = ret != null ? f(ret, k, v) : {
            k: v
          };
        }
        return ret;
      }
    };
  };

  root.take = function(n) {
    return function(xs) {
      if (n != null) {
        return xs.slice(0, (n - 1) + 1 || 9e9);
      } else {
        return xs;
      }
    };
  };

  root.omap = function(f) {
    return function(xs) {
      var merger;
      merger = function(a, oldk, oldv) {
        var newk, newv, _ref2;
        _ref2 = f(oldk, oldv), newk = _ref2[0], newv = _ref2[1];
        a[newk] = newv;
        return a;
      };
      return (root.fold({}, merger))(xs);
    };
  };

  root.copy = root.omap(function(k, v) {
    return [k, v];
  });

  root.partition = function(f) {
    return function(xs) {
      var falses, trues, x, _i, _len;
      trues = [];
      falses = [];
      for (_i = 0, _len = xs.length; _i < _len; _i++) {
        x = xs[_i];
        if (f(x)) {
          trues.push(x);
        } else {
          falses.push(x);
        }
      }
      return [trues, falses];
    };
  };

  root.concatMap = function(f) {
    return function(xs) {
      var fx, k, ret, v, x, _i, _len;
      ret = void 0;
      for (_i = 0, _len = xs.length; _i < _len; _i++) {
        x = xs[_i];
        fx = f(x);
        ret = (function() {
          var _ref2;
          if (ret === void 0) {
            return fx;
          } else if ((_ref2 = typeof fx) === 'string' || _ref2 === 'number') {
            return ret + fx;
          } else if (fx.slice != null) {
            return ret.concat(fx);
          } else {
            for (k in fx) {
              v = fx[k];
              ret[k] = v;
            }
            return ret;
          }
        })();
      }
      return ret;
    };
  };

  root.flatMap = root.concatMap;

  root.sum = root.concatMap(function() {});

  root.AND = function(a, b) {
    return a && b;
  };

  root.OR = function(a, b) {
    return a || b;
  };

  root.NOT = function(x) {
    return !x;
  };

  root.id = id = function(x) {
    return x;
  };

  root.any = function(xs, f) {
    var x, _i, _len;
    if (f == null) {
      f = id;
    }
    for (_i = 0, _len = xs.length; _i < _len; _i++) {
      x = xs[_i];
      if (f(x)) {
        return true;
      }
    }
    return false;
  };

  root.invoke = function() {
    var args, name;
    name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return function(obj) {
      var _ref2;
      if ((_ref2 = obj[name]) != null ? _ref2.apply : void 0) {
        return obj[name].apply(obj, args);
      } else {
        return Deferred().reject("No method: " + name).promise();
      }
    };
  };

  root.invokeWith = function(name, args, ctx) {
    if (args == null) {
      args = [];
    }
    if (ctx == null) {
      ctx = null;
    }
    return function(o) {
      return o[name].apply(ctx || o, args);
    };
  };

  root.get = function(name) {
    return function(obj) {
      return obj[name];
    };
  };

  root.set = function(name, value) {
    return function(obj) {
      var k, v;
      if (arguments.length === 2) {
        obj[name] = value;
      } else {
        for (k in name) {
          if (!__hasProp.call(name, k)) continue;
          v = name[k];
          obj[k] = v;
        }
      }
      return obj;
    };
  };

  root.flip = function(f) {
    return function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return f.apply(null, args.reverse());
    };
  };

  REQUIRES = function(required, got) {
    return "This service requires a service at version " + required + " or above. This one is at " + got;
  };

  root.REQUIRES_VERSION = function(s, n, f) {
    return s.fetchVersion().pipe(function(v) {
      if (v >= n) {
        return f();
      } else {
        return error(REQUIRES(n, v));
      }
    });
  };

  root.dejoin = function(q) {
    var parts, view, _i, _len, _ref2;
    _ref2 = q.views;
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      view = _ref2[_i];
      parts = view.split('.');
      if (parts.length > 2) {
        q.addJoin(parts.slice(1, -1).join('.'));
      }
    }
    return q;
  };

  root.sequence = function() {
    var fld, fns;
    fns = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    fld = fold(success(), function(p, f) {
      return p.then(f);
    });
    return fld(_.flatten(fns));
  };

}).call(this);

(function() {
  var ACCEPT_HEADER, CHECKING_PIPE, ERROR_PIPE, XDomainRequest, error, get, http, inIE9, intermine, jQuery, mappingForIE, wrapCbs, _ref, _ref1;

  jQuery = this.jQuery, intermine = this.intermine, XDomainRequest = this.XDomainRequest;

  http = ((_ref = intermine.http) != null ? _ref : intermine.http = {});

  ACCEPT_HEADER = intermine.constants.ACCEPT_HEADER;

  _ref1 = intermine.funcutils, get = _ref1.get, error = _ref1.error;

  (function() {
    var converters, format, header;
    converters = {};
    for (format in ACCEPT_HEADER) {
      header = ACCEPT_HEADER[format];
      converters["text " + format] = jQuery.parseJSON;
    }
    return jQuery.ajaxSetup({
      accepts: ACCEPT_HEADER,
      contents: {
        json: /json/
      },
      converters: converters
    });
  })();

  CHECKING_PIPE = function(response) {
    return jQuery.Deferred(function() {
      if (response.wasSuccessful) {
        return this.resolve(response);
      } else {
        return this.reject(response.error, response);
      }
    });
  };

  ERROR_PIPE = function(xhr, textStatus, e) {
    try {
      return JSON.parse(xhr.responseText).error;
    } catch (e) {
      return textStatus;
    }
  };

  inIE9 = XDomainRequest != null;

  mappingForIE = {
    PUT: 'POST',
    DELETE: 'GET'
  };

  if (inIE9) {
    http.getMethod = function(x) {
      var _ref2;
      return (_ref2 = mappingForIE[x]) != null ? _ref2 : x;
    };
    http.supports = function(m) {
      return !(x in mappingForIE);
    };
  } else {
    http.getMethod = function(x) {
      return x;
    };
    http.supports = function() {
      return true;
    };
  }

  wrapCbs = function(cbs) {
    var atEnd, doThis, err, _doThis;
    if (_.isArray(cbs)) {
      if (!cbs.length) {
        return [];
      }
      doThis = cbs[0], err = cbs[1], atEnd = cbs[2];
      _doThis = function(rows) {
        return _.each(rows, doThis != null ? doThis : function() {});
      };
      return [_doThis, err, atEnd];
    } else {
      _doThis = function(rows) {
        return _.each(rows, cbs != null ? cbs : function() {});
      };
      return [_doThis];
    }
  };

  http.iterReq = function(method, path, fmt) {
    return function(q, page, doThis, onErr, onEnd) {
      var req, _doThis, _ref2;
      if (page == null) {
        page = {};
      }
      if (doThis == null) {
        doThis = (function() {});
      }
      if (onErr == null) {
        onErr = (function() {});
      }
      if (onEnd == null) {
        onEnd = (function() {});
      }
      if (arguments.length === 2 && _.isFunction(page)) {
        _ref2 = [page, {}], doThis = _ref2[0], page = _ref2[1];
      }
      req = _.extend({
        format: fmt
      }, page, {
        query: q.toXML()
      });
      _doThis = function(rows) {
        return rows.forEach(doThis);
      };
      return this.makeRequest(method, path, req).fail(onErr).pipe(get('results')).done(doThis).done(onEnd);
    };
  };

  http.doReq = function(opts) {
    var errBack;
    errBack = opts.error || this.errorHandler;
    opts.error = _.compose(errBack, ERROR_PIPE);
    return jQuery.ajax(opts).pipe(CHECKING_PIPE).fail(errBack);
  };

}).call(this);

(function() {
  var IS_NODE, Table, merge, properties, __root__, _ref;

  IS_NODE = typeof exports !== 'undefined';

  __root__ = typeof exports !== "undefined" && exports !== null ? exports : ((_ref = this.intermine) != null ? _ref : this.intermine = {});

  merge = function(src, dest) {
    var k, v, _results;
    _results = [];
    for (k in src) {
      v = src[k];
      _results.push(dest[k] = v);
    }
    return _results;
  };

  properties = ['attributes', 'references', 'collections'];

  Table = (function() {

    function Table(_arg) {
      var c, prop, _, _i, _len, _ref1;
      this.name = _arg.name, this.attributes = _arg.attributes, this.references = _arg.references, this.collections = _arg.collections;
      this.fields = {};
      this.__parents__ = arguments[0]['extends'];
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        prop = properties[_i];
        merge(this[prop], this.fields);
      }
      _ref1 = this.collections;
      for (_ in _ref1) {
        c = _ref1[_];
        c.isCollection = true;
      }
    }

    Table.prototype.toString = function() {
      var n, _;
      return "[Table name=" + this.name + ", fields=[" + ((function() {
        var _ref1, _results;
        _ref1 = this.fields;
        _results = [];
        for (n in _ref1) {
          _ = _ref1[n];
          _results.push(n);
        }
        return _results;
      }).call(this)) + "]]";
    };

    Table.prototype.parents = function() {
      var _ref1;
      return ((_ref1 = this.__parents__) != null ? _ref1 : []).slice();
    };

    return Table;

  })();

  __root__.Table = Table;

}).call(this);

(function() {
  var $, Deferred, IS_NODE, NAMES, PARSED, PathInfo, any, concatMap, copy, error, get, intermine, makeKey, set, success, utils, _, __root__,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  IS_NODE = typeof exports !== 'undefined';

  __root__ = typeof exports !== "undefined" && exports !== null ? exports : this;

  if (IS_NODE) {
    intermine = __root__;
    _ = require('underscore')._;
    Deferred = ($ = require('underscore.deferred')).Deferred;
    utils = require('./util');
  } else {
    _ = __root__._;
    Deferred = ($ = __root__.jQuery).Deferred;
    intermine = __root__.intermine;
    utils = intermine.funcutils;
  }

  concatMap = utils.concatMap, get = utils.get, any = utils.any, set = utils.set, copy = utils.copy, success = utils.success, error = utils.error;

  NAMES = {};

  PARSED = {};

  makeKey = function(model, path, subclasses) {
    var k, v, _ref;
    return "" + (model != null ? model.name : void 0) + "|" + (model != null ? (_ref = model.service) != null ? _ref.root : void 0 : void 0) + "|" + path + ":" + ((function() {
      var _results;
      _results = [];
      for (k in subclasses) {
        v = subclasses[k];
        _results.push("" + k + "=" + v);
      }
      return _results;
    })());
  };

  PathInfo = (function() {

    function PathInfo(_arg) {
      var _ref;
      this.root = _arg.root, this.model = _arg.model, this.descriptors = _arg.descriptors, this.subclasses = _arg.subclasses, this.displayName = _arg.displayName, this.ident = _arg.ident;
      this.allDescriptors = __bind(this.allDescriptors, this);

      this.getChildNodes = __bind(this.getChildNodes, this);

      this.getDisplayName = __bind(this.getDisplayName, this);

      this.isa = __bind(this.isa, this);

      this.append = __bind(this.append, this);

      this.getParent = __bind(this.getParent, this);

      this.getEndClass = __bind(this.getEndClass, this);

      this.containsCollection = __bind(this.containsCollection, this);

      this.isCollection = __bind(this.isCollection, this);

      this.isReference = __bind(this.isReference, this);

      this.isClass = __bind(this.isClass, this);

      this.isAttribute = __bind(this.isAttribute, this);

      this.isRoot = __bind(this.isRoot, this);

      this.end = _.last(this.descriptors);
      if ((_ref = this.ident) == null) {
        this.ident = makeKey(this.model, this, this.subclasses);
      }
    }

    PathInfo.prototype.isRoot = function() {
      return this.descriptors.length === 0;
    };

    PathInfo.prototype.isAttribute = function() {
      return (this.end != null) && !(this.end.referencedType != null);
    };

    PathInfo.prototype.isClass = function() {
      return this.isRoot() || (this.end.referencedType != null);
    };

    PathInfo.prototype.isReference = function() {
      var _ref;
      return ((_ref = this.end) != null ? _ref.referencedType : void 0) != null;
    };

    PathInfo.prototype.isCollection = function() {
      var _ref, _ref1;
      return (_ref = (_ref1 = this.end) != null ? _ref1.isCollection : void 0) != null ? _ref : false;
    };

    PathInfo.prototype.containsCollection = function() {
      return any(this.descriptors, function(x) {
        return x.isCollection;
      });
    };

    PathInfo.prototype.getEndClass = function() {
      var _ref;
      return this.model.classes[this.subclasses[this.toString()] || ((_ref = this.end) != null ? _ref.referencedType : void 0)] || this.root;
    };

    PathInfo.prototype.getParent = function() {
      var data;
      if (this.isRoot()) {
        throw new Error("Root paths do not have parents");
      }
      data = {
        root: this.root,
        model: this.model,
        descriptors: _.initial(this.descriptors),
        subclasses: this.subclasses
      };
      return new PathInfo(data);
    };

    PathInfo.prototype.append = function(attr) {
      var data, fld;
      if (this.isAttribute()) {
        throw new Error("" + this + " is an attribute.");
      }
      fld = _.isString(attr) ? this.getType().fields[attr] : attr;
      if (fld == null) {
        throw new Error("" + attr + " is not a field of " + (this.getType()));
      }
      data = {
        root: this.root,
        model: this.model,
        descriptors: this.descriptors.concat(fld),
        subclasses: this.subclasses
      };
      return new PathInfo(data);
    };

    PathInfo.prototype.isa = function(clazz) {
      var name, type;
      if (this.isAttribute()) {
        return this.getType() === clazz;
      } else {
        name = clazz.name ? clazz.name : '' + clazz;
        type = this.getType();
        return (name === type.name) || (__indexOf.call(this.model.getAncestorsOf(type), name) >= 0);
      }
    };

    PathInfo.prototype.getDisplayName = function(cb) {
      var cached, params, path, _ref,
        _this = this;
      if ((_ref = this.namePromise) == null) {
        this.namePromise = (cached = this.displayName || NAMES[this.ident]) ? success(cached) : !(this.model.service != null) ? error("No service") : (path = 'model' + (concatMap(function(d) {
          return '/' + d.name;
        }))(this.allDescriptors()), params = (set({
          format: 'json'
        }))(copy(this.subclasses)), this.model.service.get(path, params).then(get('display')).done(function(n) {
          var _name, _ref1;
          return (_ref1 = NAMES[_name = _this.ident]) != null ? _ref1 : NAMES[_name] = n;
        }));
      }
      return this.namePromise.done(cb);
    };

    PathInfo.prototype.getChildNodes = function() {
      var fld, name, _ref, _ref1, _results;
      _ref1 = ((_ref = this.getEndClass()) != null ? _ref.fields : void 0) || {};
      _results = [];
      for (name in _ref1) {
        fld = _ref1[name];
        _results.push(this.append(fld));
      }
      return _results;
    };

    PathInfo.prototype.allDescriptors = function() {
      return [this.root].concat(this.descriptors);
    };

    PathInfo.prototype.toString = function() {
      return this.allDescriptors().map(get('name')).join('.');
    };

    PathInfo.prototype.equals = function(other) {
      return other && (other.ident != null) && this.ident === other.ident;
    };

    PathInfo.prototype.getType = function() {
      var _ref, _ref1;
      return ((_ref = this.end) != null ? (_ref1 = _ref.type) != null ? _ref1.replace(/java\.lang\./, '') : void 0 : void 0) || this.getEndClass();
    };

    return PathInfo;

  })();

  PathInfo.prototype.toPathString = PathInfo.prototype.toString;

  PathInfo.parse = function(model, path, subclasses) {
    var cached, cd, descriptors, fld, ident, keyPath, part, parts, root;
    if (subclasses == null) {
      subclasses = {};
    }
    ident = makeKey(model, path, subclasses);
    if (cached = PARSED[ident]) {
      return cached;
    }
    parts = (path + '').split('.');
    root = cd = model.classes[parts.shift()];
    keyPath = root.name;
    descriptors = (function() {
      var _i, _len, _ref, _results;
      _results = [];
      for (_i = 0, _len = parts.length; _i < _len; _i++) {
        part = parts[_i];
        fld = (cd != null ? cd.fields[part] : void 0) || ((_ref = (cd = model.classes[subclasses[keyPath]])) != null ? _ref.fields[part] : void 0);
        if (!fld) {
          throw new Error("Could not find " + part + " in " + cd + " when parsing " + path);
        }
        keyPath += "." + part;
        cd = model.classes[fld.type || fld.referencedType];
        _results.push(fld);
      }
      return _results;
    })();
    return PARSED[ident] = new PathInfo({
      root: root,
      model: model,
      descriptors: descriptors,
      subclasses: subclasses,
      ident: ident
    });
  };

  PathInfo.flushCache = function() {
    PARSED = {};
    return NAMES = {};
  };

  intermine.PathInfo = PathInfo;

}).call(this);

(function() {
  var $, Deferred, IS_NODE, Model, PathInfo, Table, flatten, intermine, intersection, liftToTable, omap, _, __root__, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  IS_NODE = typeof exports !== 'undefined';

  __root__ = typeof exports !== "undefined" && exports !== null ? exports : this;

  if (IS_NODE) {
    intermine = __root__;
    _ = require('underscore')._;
    Deferred = ($ = require('underscore.deferred')).Deferred;
    Table = require('./table').Table;
    PathInfo = require('./path').PathInfo;
    omap = require('./util').omap;
  } else {
    _ = __root__._;
    Deferred = ($ = __root__.jQuery).Deferred;
    intermine = ((_ref = __root__.intermine) != null ? _ref : __root__.intermine = {});
    Table = intermine.Table, PathInfo = intermine.PathInfo;
    omap = intermine.funcutils.omap;
  }

  flatten = _.flatten, intersection = _.intersection;

  liftToTable = omap(function(k, v) {
    return [k, new Table(v)];
  });

  Model = (function() {

    function Model(_arg) {
      var classes;
      this.name = _arg.name, classes = _arg.classes;
      this.findCommonType = __bind(this.findCommonType, this);

      this.findSharedAncestor = __bind(this.findSharedAncestor, this);

      this.getAncestorsOf = __bind(this.getAncestorsOf, this);

      this.getSubclassesOf = __bind(this.getSubclassesOf, this);

      this.getPathInfo = __bind(this.getPathInfo, this);

      this.classes = liftToTable(classes);
    }

    Model.prototype.getPathInfo = function(path, subcls) {
      return PathInfo.parse(this, path, subcls);
    };

    Model.prototype.getSubclassesOf = function(cls) {
      var cd, clazz, ret, _ref1, _ref2;
      clazz = cls && cls.name ? cls : this.classes[cls];
      if (clazz == null) {
        throw new Error("" + cls + " is not a table");
      }
      ret = [clazz.name];
      _ref1 = this.classes;
      for (_ in _ref1) {
        cd = _ref1[_];
        if (_ref2 = clazz.name, __indexOf.call(cd.parents(), _ref2) >= 0) {
          ret = ret.concat(this.getSubclassesOf(cd));
        }
      }
      return ret;
    };

    Model.prototype.getAncestorsOf = function(cls) {
      var ancestors, clazz, superC, _i, _len;
      clazz = cls && cls.name ? cls : this.classes[cls];
      if (clazz == null) {
        throw new Error("" + cls + " is not a table");
      }
      ancestors = clazz.parents();
      for (_i = 0, _len = ancestors.length; _i < _len; _i++) {
        superC = ancestors[_i];
        ancestors.push(this.getAncestorsOf(superC));
      }
      return flatten(ancestors);
    };

    Model.prototype.findSharedAncestor = function(classA, classB) {
      var a_ancestry, b_ancestry;
      if (classB === null || classA === null) {
        return null;
      }
      if (classA === classB) {
        return classA;
      }
      a_ancestry = this.getAncestorsOf(classA);
      if (__indexOf.call(a_ancestry, classB) >= 0) {
        return classB;
      }
      b_ancestry = this.getAncestorsOf(classB);
      if (__indexOf.call(b_ancestry, classA) >= 0) {
        return classA;
      }
      return intersection(a_ancestry, b_ancestry).shift();
    };

    Model.prototype.findCommonType = function(xs) {
      if (xs == null) {
        xs = [];
      }
      return xs.reduce(this.findSharedAncestor);
    };

    return Model;

  })();

  Model.prototype.makePath = Model.prototype.getPathInfo;

  Model.prototype.findCommonTypeOfMultipleClasses = Model.prototype.findCommonType;

  Model.load = function(data) {
    return new Model(data);
  };

  Model.INTEGRAL_TYPES = ["int", "Integer", "long", "Long"];

  Model.FRACTIONAL_TYPES = ["double", "Double", "float", "Float"];

  Model.NUMERIC_TYPES = Model.INTEGRAL_TYPES.concat(Model.FRACTIONAL_TYPES);

  Model.BOOLEAN_TYPES = ["boolean", "Boolean"];

  intermine.Model = Model;

}).call(this);

(function() {
  var Deferred, IS_NODE, User, do_pref_req, error, intermine, _, __root__,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  IS_NODE = typeof exports !== 'undefined';

  __root__ = typeof exports !== "undefined" && exports !== null ? exports : this;

  if (IS_NODE) {
    Deferred = require('underscore.deferred').Deferred;
    _ = require('underscore')._;
    error = require('./util').error;
    intermine = __root__;
  } else {
    _ = __root__._;
    Deferred = __root__.jQuery.Deferred;
    intermine = __root__.intermine;
    error = intermine.funcutils.error;
  }

  do_pref_req = function(user, data, method) {
    return user.service.manageUserPreferences(method, data).done(function(prefs) {
      return user.preferences = prefs;
    });
  };

  User = (function() {

    function User(service, _arg) {
      var _ref;
      this.service = service;
      this.username = _arg.username, this.preferences = _arg.preferences;
      this.refresh = __bind(this.refresh, this);

      this.clearPreferences = __bind(this.clearPreferences, this);

      this.clearPreference = __bind(this.clearPreference, this);

      this.setPreferences = __bind(this.setPreferences, this);

      this.setPreference = __bind(this.setPreference, this);

      this.hasPreferences = this.preferences != null;
      if ((_ref = this.preferences) == null) {
        this.preferences = {};
      }
    }

    User.prototype.setPreference = function(key, value) {
      var data;
      if (_.isString(key)) {
        data = {};
        data[key] = value;
      } else if (!(value != null)) {
        data = key;
      } else {
        error("Incorrect arguments to setPreference");
      }
      return this.setPreferences(data);
    };

    User.prototype.setPreferences = function(prefs) {
      return do_pref_req(this, prefs, 'POST');
    };

    User.prototype.clearPreference = function(key) {
      return do_pref_req(this, {
        key: key
      }, 'DELETE');
    };

    User.prototype.clearPreferences = function() {
      return do_pref_req(this, {}, 'DELETE');
    };

    User.prototype.refresh = function() {
      return do_pref_req(this, {}, 'GET');
    };

    return User;

  })();

  intermine.User = User;

}).call(this);

(function() {
  var INVITES, IS_NODE, List, REQUIRES_VERSION, SHARES, TAGS_PATH, dejoin, funcutils, get, getFolderName, intermine, invoke, isFolder, set, _, __root__,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  IS_NODE = typeof exports !== 'undefined';

  __root__ = typeof exports !== "undefined" && exports !== null ? exports : this;

  if (IS_NODE) {
    _ = require('underscore')._;
    funcutils = require('./util');
    intermine = __root__;
  } else {
    _ = __root__._, intermine = __root__.intermine;
    funcutils = intermine.funcutils;
  }

  get = funcutils.get, invoke = funcutils.invoke, REQUIRES_VERSION = funcutils.REQUIRES_VERSION, set = funcutils.set, dejoin = funcutils.dejoin;

  TAGS_PATH = "list/tags";

  SHARES = "lists/shares";

  INVITES = 'lists/invitations';

  isFolder = function(t) {
    return t.substr(0, t.indexOf(':')) === '__folder__';
  };

  getFolderName = function(t) {
    return s.substr(t.indexOf(':') + 1);
  };

  List = (function() {

    function List(properties, service) {
      var k, v;
      this.service = service;
      this.hasTag = __bind(this.hasTag, this);

      for (k in properties) {
        if (!__hasProp.call(properties, k)) continue;
        v = properties[k];
        this[k] = v;
      }
      this.dateCreated = (this.dateCreated != null) ? new Date(this.dateCreated) : null;
      this.folders = this.tags.filter(isFolder).map(getFolderName);
    }

    List.prototype.hasTag = function(t) {
      return __indexOf.call(this.tags, t) >= 0;
    };

    List.prototype.query = function(view) {
      if (view == null) {
        view = ['*'];
      }
      return this.service.query({
        select: view,
        from: this.type,
        where: [[this.type, 'IN', this.name]]
      });
    };

    List.prototype.del = function(cb) {
      return this.service.makeRequest('DELETE', 'lists', {
        name: this.name
      }, cb);
    };

    List.prototype.contents = function(cb) {
      return this.query().pipe(dejoin).pipe(invoke('records')).done(cb);
    };

    List.prototype.rename = function(newName, cb) {
      var _this = this;
      return this.service.post('lists/rename', {
        oldname: this.name,
        newname: newName
      }).pipe(get('listName')).done(function(n) {
        return _this.name = n;
      }).pipe(this.service.fetchList).done(cb);
    };

    List.prototype.copy = function(opts, cb) {
      var baseName, name, query, tags, _ref, _ref1, _ref2,
        _this = this;
      if (opts == null) {
        opts = {};
      }
      if (cb == null) {
        cb = (function() {});
      }
      if (arguments.length === 1 && _.isFunction(opts)) {
        _ref = [{}, opts], opts = _ref[0], cb = _ref[1];
      }
      if (_.isString(opts)) {
        opts = {
          name: '' + opts
        };
      }
      name = baseName = (_ref1 = opts.name) != null ? _ref1 : "" + this.name + "_copy";
      tags = this.tags.concat((_ref2 = opts.tags) != null ? _ref2 : []);
      query = this.query(['id']);
      return this.service.fetchLists().pipe(invoke('map', get('name'))).pipe(function(names) {
        var c;
        c = 1;
        while (__indexOf.call(names, name) >= 0) {
          name = "" + baseName + "-" + (c++);
        }
        return query.pipe(invoke('saveAsList', {
          name: name,
          tags: tags,
          description: _this.description
        })).done(cb);
      });
    };

    List.prototype.enrichment = function(opts, cb) {
      return this.service.enrichment((set({
        list: this.name
      }))(opts), cb);
    };

    List.prototype.shareWithUser = function(recipient, cb) {
      return this.service.post(SHARES, {
        list: this.name,
        "with": recipient
      }).done(cb);
    };

    List.prototype.inviteUserToShare = function(recipient, notify, cb) {
      if (notify == null) {
        notify = true;
      }
      if (cb == null) {
        cb = (function() {});
      }
      return this.service.post(INVITES, {
        list: this.name,
        to: recipient,
        notify: !!notify
      }).done(cb);
    };

    return List;

  })();

  intermine.List = List;

}).call(this);

(function() {
  var Deferred, IDResolutionJob, IS_NODE, funcutils, get, intermine, __root__,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  IS_NODE = typeof exports !== 'undefined';

  __root__ = typeof exports !== "undefined" && exports !== null ? exports : this;

  if (IS_NODE) {
    Deferred = require('underscore.deferred').Deferred;
    funcutils = require('./util');
    intermine = __root__;
  } else {
    Deferred = __root__.jQuery.Deferred;
    intermine = __root__.intermine;
    funcutils = intermine.funcutils;
  }

  get = funcutils.get;

  IDResolutionJob = (function() {

    function IDResolutionJob(uid, service) {
      this.uid = uid;
      this.service = service;
      this.del = __bind(this.del, this);

      this.fetchResults = __bind(this.fetchResults, this);

      this.fetchErrorMessage = __bind(this.fetchErrorMessage, this);

      this.fetchStatus = __bind(this.fetchStatus, this);

    }

    IDResolutionJob.prototype.fetchStatus = function(cb) {
      return this.service.get("ids/" + this.uid + "/status").pipe(get('status')).done(cb);
    };

    IDResolutionJob.prototype.fetchErrorMessage = function(cb) {
      return this.service.get("ids/" + this.uid + "/status").pipe(get('message')).done(cb);
    };

    IDResolutionJob.prototype.fetchResults = function(cb) {
      return this.service.get("ids/" + this.uid + "/result").pipe(get('results')).done(cb);
    };

    IDResolutionJob.prototype.del = function(cb) {
      return this.service.makeRequest('DELETE', "ids/" + this.uid, {}, cb);
    };

    IDResolutionJob.prototype.poll = function(onSuccess, onError, onProgress) {
      var resp, ret,
        _this = this;
      ret = Deferred().done(onSuccess).fail(onError).progress(onProgress);
      resp = this.fetchStatus();
      resp.fail(ret.reject);
      resp.done(function(status) {
        ret.notify(status);
        switch (status) {
          case 'SUCCESS':
            return _this.fetchResults().then(ret.resolve, ret.reject);
          case 'ERROR':
            return _this.fetchErrorMessage().then(ret.reject, ret.reject);
          default:
            return _this.poll(ret.resolve, ret.reject, ret.notify);
        }
      });
      return ret.promise();
    };

    return IDResolutionJob;

  })();

  IDResolutionJob.create = function(service) {
    return function(uid) {
      return new IDResolutionJob(uid, service);
    };
  };

  intermine.IDResolutionJob = IDResolutionJob;

}).call(this);

(function() {
  var $, BASIC_ATTRS, CODES, Deferred, IS_NODE, LIST_PIPE, Query, RESULTS_METHODS, SIMPLE_ATTRS, conAttrs, conStr, conValStr, concatMap, decapitate, didntRemove, f, fold, get, get_canonical_op, id, idConStr, intermine, interpretConArray, interpretConstraint, jQuery, mth, multiConStr, noValueConStr, partition, simpleConStr, take, toQueryString, typeConStr, _, __root__, _fn, _get_data_fetcher, _i, _j, _len, _len1, _ref, _ref1, _ref2,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  IS_NODE = typeof exports !== 'undefined';

  __root__ = typeof exports !== "undefined" && exports !== null ? exports : this;

  if (IS_NODE) {
    intermine = __root__;
    _ = require('underscore')._;
    Deferred = ($ = require('underscore.deferred')).Deferred;
    toQueryString = require('querystring').stringify;
    _ref = require('./util'), partition = _ref.partition, fold = _ref.fold, take = _ref.take, concatMap = _ref.concatMap, id = _ref.id, get = _ref.get;
  } else {
    _ = __root__._, jQuery = __root__.jQuery, intermine = __root__.intermine;
    _ref1 = intermine.funcutils, partition = _ref1.partition, fold = _ref1.fold, take = _ref1.take, concatMap = _ref1.concatMap, id = _ref1.id, get = _ref1.get;
    Deferred = ($ = jQuery).Deferred;
    toQueryString = function(obj) {
      return jQuery.param(obj, true);
    };
  }

  get_canonical_op = function(orig) {
    var canonical;
    canonical = _.isString(orig) ? Query.OP_DICT[orig.toLowerCase()] : null;
    if (!canonical) {
      throw new Error("Illegal constraint operator: " + orig);
    }
    return canonical;
  };

  BASIC_ATTRS = ['path', 'op', 'code'];

  SIMPLE_ATTRS = BASIC_ATTRS.concat(['value', 'extraValue']);

  RESULTS_METHODS = ['rowByRow', 'eachRow', 'recordByRecord', 'eachRecord', 'records', 'rows', 'table', 'tableRows'];

  LIST_PIPE = function(service) {
    return _.compose(service.fetchList, get('listName'));
  };

  CODES = [null, 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];

  decapitate = function(x) {
    return x.substr(x.indexOf('.'));
  };

  conValStr = function(v) {
    return "<value>" + (_.escape(v)) + "</value>";
  };

  conAttrs = function(c, names) {
    var k, v;
    return ((function() {
      var _results;
      _results = [];
      for (k in c) {
        v = c[k];
        if ((__indexOf.call(names, k) >= 0)) {
          _results.push("" + k + "=\"" + (_.escape(v)) + "\" ");
        }
      }
      return _results;
    })()).join('');
  };

  noValueConStr = function(c) {
    return "<constraint " + (conAttrs(c, BASIC_ATTRS)) + "/>";
  };

  typeConStr = function(c) {
    return "<constraint " + (conAttrs(c, ['path', 'type'])) + "/>";
  };

  simpleConStr = function(c) {
    return "<constraint " + (conAttrs(c, SIMPLE_ATTRS)) + "/>";
  };

  multiConStr = function(c) {
    return "<constraint " + (conAttrs(c, BASIC_ATTRS)) + ">" + (concatMap(conValStr)(c.values)) + "</constraint>";
  };

  idConStr = function(c) {
    return "<constraint " + (conAttrs(c, BASIC_ATTRS)) + "ids=\"" + (c.ids.join(',')) + "\"/>";
  };

  conStr = function(c) {
    var _ref2;
    if (c.values != null) {
      return multiConStr(c);
    } else if (c.ids != null) {
      return idConStr(c);
    } else if (!(c.op != null)) {
      return typeConStr(c);
    } else if (_ref2 = c.op, __indexOf.call(Query.NULL_OPS, _ref2) >= 0) {
      return noValueConStr(c);
    } else {
      return simpleConStr(c);
    }
  };

  didntRemove = function(orig, reduced) {
    return "Did not remove a single constraint. original = " + orig + ", reduced = " + reduced;
  };

  interpretConstraint = function(path, con) {
    var constraint, k, keys, v, x, _ref2;
    constraint = {
      path: path
    };
    if (con === null) {
      constraint.op = 'IS NULL';
    } else if (_.isArray(con)) {
      constraint.op = 'ONE OF';
      constraint.values = con;
    } else if (_.isString(con) || _.isNumber(con)) {
      if (_ref2 = typeof con.toUpperCase === "function" ? con.toUpperCase() : void 0, __indexOf.call(Query.NULL_OPS, _ref2) >= 0) {
        constraint.op = con;
      } else {
        constraint.op = '=';
        constraint.value = con;
      }
    } else {
      keys = (function() {
        var _results;
        _results = [];
        for (k in con) {
          x = con[k];
          _results.push(k);
        }
        return _results;
      })();
      if (__indexOf.call(keys, 'isa') >= 0) {
        if (_.isArray(con.isa)) {
          constraint.op = k;
          constraint.values = con.isa;
        } else {
          constraint.type = con.isa;
        }
      } else {
        if (__indexOf.call(keys, 'extraValue') >= 0) {
          constraint.extraValue = con.extraValue;
        }
        for (k in con) {
          v = con[k];
          if (!(k !== 'extraValue')) {
            continue;
          }
          constraint.op = k;
          if (_.isArray(v)) {
            constraint.values = v;
          } else {
            constraint.value = v;
          }
        }
      }
    }
    return constraint;
  };

  interpretConArray = function(conArgs) {
    var a0, constraint, v, _ref2;
    conArgs = conArgs.slice();
    constraint = {
      path: conArgs.shift()
    };
    if (conArgs.length === 1) {
      a0 = conArgs[0];
      if (_ref2 = typeof a0.toUpperCase === "function" ? a0.toUpperCase() : void 0, __indexOf.call(Query.NULL_OPS, _ref2) >= 0) {
        constraint.op = a0;
      } else {
        constraint.type = a0;
      }
    } else if (conArgs.length >= 2) {
      constraint.op = conArgs[0];
      v = conArgs[1];
      if (_.isArray(v)) {
        constraint.values = v;
      } else {
        constraint.value = v;
      }
      if (conArgs.length === 3) {
        constraint.extraValue = conArgs[2];
      }
    }
    return constraint;
  };

  Query = (function() {
    var getPaths;

    Query.JOIN_STYLES = ['INNER', 'OUTER'];

    Query.BIO_FORMATS = ['gff3', 'fasta', 'bed'];

    Query.NULL_OPS = ['IS NULL', 'IS NOT NULL'];

    Query.ATTRIBUTE_VALUE_OPS = ["=", "!=", ">", ">=", "<", "<=", "CONTAINS", "LIKE", "NOT LIKE"];

    Query.MULTIVALUE_OPS = ['ONE OF', 'NONE OF'];

    Query.TERNARY_OPS = ['LOOKUP'];

    Query.LOOP_OPS = ['=', '!='];

    Query.LIST_OPS = ['IN', 'NOT IN'];

    Query.OP_DICT = {
      '=': '=',
      '==': '=',
      'eq': '=',
      '!=': '!=',
      'ne': '!=',
      '>': '>',
      'gt': '>',
      '>=': '>=',
      'ge': '>=',
      '<': '<',
      'lt': '<',
      '<=': '<=',
      'le': '<=',
      'contains': 'CONTAINS',
      'CONTAINS': 'CONTAINS',
      'like': 'LIKE',
      'LIKE': 'LIKE',
      'not like': 'NOT LIKE',
      'NOT LIKE': 'NOT LIKE',
      'lookup': 'LOOKUP',
      'IS NULL': 'IS NULL',
      'is null': 'IS NULL',
      'IS NOT NULL': 'IS NOT NULL',
      'is not null': 'IS NOT NULL',
      'ONE OF': 'ONE OF',
      'one of': 'ONE OF',
      'NONE OF': 'NONE OF',
      'none of': 'NONE OF',
      'in': 'IN',
      'not in': 'NOT IN',
      'IN': 'IN',
      'NOT IN': 'NOT IN',
      'WITHIN': 'WITHIN',
      'within': 'WITHIN',
      'OVERLAPS': 'OVERLAPS',
      'overlaps': 'OVERLAPS',
      'ISA': 'ISA',
      'isa': 'ISA'
    };

    getPaths = function() {};

    Query.prototype.on = function(events, callback, context) {
      var calls, ev, list, tail, _ref2, _ref3, _ref4;
      events = events.split(/\s+/);
      calls = ((_ref2 = this._callbacks) != null ? _ref2 : this._callbacks = {});
      while (ev = events.shift()) {
        list = ((_ref3 = calls[ev]) != null ? _ref3 : calls[ev] = {});
        tail = ((_ref4 = list.tail) != null ? _ref4 : list.tail = (list.next = {}));
        tail.callback = callback;
        tail.context = context;
        list.tail = tail.next = {};
      }
      return this;
    };

    Query.prototype.bind = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.on.apply(this, args);
    };

    Query.prototype.trigger = function() {
      var all, args, calls, event, events, node, rest, tail;
      events = arguments[0], rest = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      calls = this._callbacks;
      if (!calls) {
        return this;
      }
      all = calls['all'];
      (events = events.split(/\s+/)).push(null);
      while (event = events.shift()) {
        if (all) {
          events.push({
            next: all.next,
            tail: all.tail,
            event: event
          });
        }
        if (!(node = calls[event])) {
          continue;
        }
        events.push({
          next: node.next,
          tail: node.tail
        });
      }
      while (node = events.pop()) {
        tail = node.tail;
        args = node.event ? [node.event].concat(rest) : rest;
        while ((node = node.next) !== tail) {
          node.callback.apply(node.context || this, args);
        }
      }
      return this;
    };

    function Query(properties, service) {
      this.addConstraint = __bind(this.addConstraint, this);

      this.expandStar = __bind(this.expandStar, this);

      this.adjustPath = __bind(this.adjustPath, this);

      this.select = __bind(this.select, this);

      var _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9,
        _this = this;
      _.defaults(this, {
        constraints: [],
        views: [],
        joins: {},
        constraintLogic: "",
        sortOrder: ""
      });
      if (properties == null) {
        properties = {};
      }
      this.displayNames = (_ref2 = properties.aliases) != null ? _ref2 : {};
      this.service = service != null ? service : {};
      this.model = (_ref3 = properties.model) != null ? _ref3 : {};
      this.summaryFields = (_ref4 = properties.summaryFields) != null ? _ref4 : {};
      this.root = (_ref5 = properties.root) != null ? _ref5 : properties.from;
      this.maxRows = (_ref6 = (_ref7 = properties.size) != null ? _ref7 : properties.limit) != null ? _ref6 : properties.maxRows;
      this.start = (_ref8 = (_ref9 = properties.start) != null ? _ref9 : properties.offset) != null ? _ref8 : 0;
      this.select(properties.views || properties.view || properties.select || []);
      this.addConstraints(properties.constraints || properties.where || []);
      this.addJoins(properties.joins || properties.join || []);
      this.orderBy(properties.sortOrder || properties.orderBy || []);
      if (properties.constraintLogic != null) {
        this.constraintLogic = properties.constraintLogic;
      }
      getPaths = function(root, depth) {
        var cd, others, ret;
        cd = _this.getPathInfo(root).getEndClass();
        ret = [root];
        others = !(cd && depth > 0) ? [] : _.flatten(_.map(cd.fields, function(r) {
          return getPaths("" + root + "." + r.name, depth - 1);
        }));
        return _.flatten(ret.concat(others));
      };
    }

    Query.prototype.removeFromSelect = function(unwanted) {
      var mapFn, so, uw, v;
      unwanted = _.isString(unwanted) ? [unwanted] : unwanted || [];
      mapFn = _.compose(this.expandStar, this.adjustPath);
      unwanted = _.flatten((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = unwanted.length; _i < _len; _i++) {
          uw = unwanted[_i];
          _results.push(mapFn(uw));
        }
        return _results;
      })());
      this.sortOrder = (function() {
        var _i, _len, _ref2, _ref3, _results;
        _ref2 = this.sortOrder;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          so = _ref2[_i];
          if (!(_ref3 = so.path, __indexOf.call(unwanted, _ref3) >= 0)) {
            _results.push(so);
          }
        }
        return _results;
      }).call(this);
      this.views = (function() {
        var _i, _len, _ref2, _results;
        _ref2 = this.views;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          v = _ref2[_i];
          if (!(__indexOf.call(unwanted, v) >= 0)) {
            _results.push(v);
          }
        }
        return _results;
      }).call(this);
      this.trigger('remove:view', unwanted);
      return this.trigger('change:views', this.views);
    };

    Query.prototype.removeConstraint = function(con, silent) {
      var c, iscon, orig, reduced;
      if (silent == null) {
        silent = false;
      }
      orig = this.constraints;
      iscon = typeof con === 'string' ? (function(c) {
        return c.code === con;
      }) : (function(c) {
        var _ref2, _ref3;
        return (c.path === con.path) && (c.op === con.op) && (c.value === con.value) && (c.extraValue === con.extraValue) && (con.type === c.type) && (((_ref2 = c.values) != null ? _ref2.join('%%') : void 0) === ((_ref3 = con.values) != null ? _ref3.join('%%') : void 0));
      });
      reduced = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = orig.length; _i < _len; _i++) {
          c = orig[_i];
          if (!iscon(c)) {
            _results.push(c);
          }
        }
        return _results;
      })();
      if (reduced.length !== orig.length - 1) {
        throw new Error(didntRemove(orig, reduced));
      }
      this.constraints = reduced;
      if (!silent) {
        this.trigger('change:constraints');
        return this.trigger('removed:constraints', _.difference(orig, reduced));
      }
    };

    Query.prototype.addToSelect = function(views) {
      var p, toAdd, _i, _len, _ref2;
      views = _.isString(views) ? [views] : views || [];
      toAdd = _.map(views, _.compose(this.expandStar, this.adjustPath));
      _ref2 = _.flatten([toAdd]);
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        p = _ref2[_i];
        this.views.push(p);
      }
      return this.trigger('add:view change:views', toAdd);
    };

    Query.prototype.select = function(views) {
      this.views = [];
      this.addToSelect(views);
      return this;
    };

    Query.prototype.adjustPath = function(path) {
      path = path && path.name ? path.name : "" + path;
      if (this.root != null) {
        if (!path.match("^" + this.root)) {
          path = this.root + "." + path;
        }
      } else {
        this.root = path.split('.')[0];
      }
      return path;
    };

    Query.prototype.getPossiblePaths = function(depth) {
      var _base, _ref2, _ref3;
      if (depth == null) {
        depth = 3;
      }
      if ((_ref2 = this._possiblePaths) == null) {
        this._possiblePaths = {};
      }
      return (_ref3 = (_base = this._possiblePaths)[depth]) != null ? _ref3 : _base[depth] = getPaths(this.root, depth);
    };

    Query.prototype.getPathInfo = function(path) {
      var adjusted, pi, _ref2;
      adjusted = this.adjustPath(path);
      pi = (_ref2 = this.model) != null ? typeof _ref2.getPathInfo === "function" ? _ref2.getPathInfo(adjusted, this.getSubclasses()) : void 0 : void 0;
      if (pi && adjusted in this.displayNames) {
        pi.displayName = this.displayNames[adjusted];
      }
      return pi;
    };

    Query.prototype.getSubclasses = function() {
      return fold({}, (function(a, c) {
        if (c.type != null) {
          a[c.path] = c.type;
        }
        return a;
      }))(this.constraints);
    };

    Query.prototype.getType = function(path) {
      return this.getPathInfo(path).getType();
    };

    Query.prototype.getViewNodes = function() {
      var toParentNode,
        _this = this;
      toParentNode = function(v) {
        return _this.getPathInfo(v).getParent();
      };
      return _.uniq(_.map(this.views, toParentNode), false, function(n) {
        return n.toPathString();
      });
    };

    Query.prototype.isInView = function(path) {
      var pi, pstr, _ref2;
      pi = this.getPathInfo(path);
      if (!pi) {
        throw new Error("Invalid path: " + path);
      }
      if (pi.isAttribute()) {
        return _ref2 = pi.toString(), __indexOf.call(this.views, _ref2) >= 0;
      } else {
        pstr = pi.toString();
        return _.any(this.getViewNodes(), function(n) {
          return n.toString() === pstr;
        });
      }
    };

    Query.prototype.canHaveMultipleValues = function(path) {
      return this.getPathInfo(path).containsCollection();
    };

    Query.prototype.getQueryNodes = function() {
      var constrainedNodes, viewNodes,
        _this = this;
      viewNodes = this.getViewNodes();
      constrainedNodes = _.map(this.constraints, function(c) {
        var pi;
        pi = _this.getPathInfo(c.path);
        if (pi.isAttribute()) {
          return pi.getParent();
        } else {
          return pi;
        }
      });
      return _.uniq(viewNodes.concat(constrainedNodes), false, function(n) {
        return n.toPathString();
      });
    };

    Query.prototype.isInQuery = function(p) {
      var pi, pstr;
      pi = this.getPathInfo(p);
      if (pi) {
        pstr = pi.toPathString();
        return _.any(_.union(this.views, _.pluck(this.constraints, 'path')), function(p) {
          return p.indexOf(pstr) === 0;
        });
      } else {
        return true;
      }
    };

    Query.prototype.isRelevant = function(path) {
      var nodes, pi, sought;
      pi = this.getPathInfo(path);
      if (pi.isAttribute()) {
        pi = pi.getParent();
      }
      sought = pi.toString();
      nodes = this.getQueryNodes();
      return _.any(nodes, function(n) {
        return n.toPathString() === sought;
      });
    };

    Query.prototype.expandStar = function(path) {
      var cd, expand, fn, n, pathStem;
      if (/\*$/.test(path)) {
        pathStem = path.substr(0, path.lastIndexOf('.'));
        expand = function(x) {
          return pathStem + x;
        };
        cd = this.getType(pathStem);
        if (/\.\*$/.test(path)) {
          if (cd && this.summaryFields[cd.name]) {
            fn = _.compose(expand, decapitate);
            return (function() {
              var _i, _len, _ref2, _results;
              _ref2 = this.summaryFields[cd.name];
              _results = [];
              for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
                n = _ref2[_i];
                if (!this.hasView(n)) {
                  _results.push(fn(n));
                }
              }
              return _results;
            }).call(this);
          }
        }
        if (/\.\*\*$/.test(path)) {
          fn = _.compose(expand, function(a) {
            return '.' + a.name;
          });
          return _.uniq(_.union(this.expandStar(pathStem + '.*'), _.map(cd.attributes, fn)));
        }
      }
      return path;
    };

    Query.prototype.isOuterJoin = function(p) {
      return this.joins[this.adjustPath(p)] === 'OUTER';
    };

    Query.prototype.hasView = function(v) {
      return this.views && _.include(this.views, this.adjustPath(v));
    };

    Query.prototype.count = function(cont) {
      if (this.service.count) {
        return this.service.count(this, cont);
      } else {
        throw new Error("This query has no service with count functionality attached.");
      }
    };

    Query.prototype.appendToList = function(target, cb) {
      var name, req, toRun, updateTarget;
      name = target && target.name ? target.name : '' + target;
      toRun = this.makeListQuery();
      req = {
        listName: name,
        query: toRun.toXML()
      };
      updateTarget = (target != null ? target.name : void 0) ? (function(list) {
        return target.size = list.size;
      }) : (function() {});
      return this.service.post('query/append/tolist', req).pipe(LIST_PIPE(this.service)).done(cb, updateTarget);
    };

    Query.prototype.makeListQuery = function() {
      var toRun, vn, _i, _len, _ref2;
      toRun = this.clone();
      if (toRun.views.length !== 1 || toRun.views[0] === null || !toRun.views[0].match(/\.id$/)) {
        toRun.select(['id']);
      }
      _ref2 = this.getViewNodes();
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        vn = _ref2[_i];
        if (!this.isOuterJoined(vn)) {
          if ((!toRun.isInView(vn)) && (vn.getEndClass().attributes.id != null)) {
            toRun.addConstraint([vn.append('id'), 'IS NOT NULL']);
          }
        }
      }
      return toRun;
    };

    Query.prototype.saveAsList = function(options, cb) {
      var req, toRun;
      toRun = this.makeListQuery();
      req = _.clone(options);
      req.listName = req.listName || req.name;
      req.query = toRun.toXML();
      if (options.tags) {
        req.tags = options.tags.join(';');
      }
      return this.service.post('query/tolist', req).pipe(LIST_PIPE(this.service)).done(cb);
    };

    Query.prototype.summarise = function(path, limit, cont) {
      return this.filterSummary(path, '', limit, cont);
    };

    Query.prototype.summarize = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.summarise.apply(this, args);
    };

    Query.prototype.filterSummary = function(path, term, limit, cont) {
      var parse, req, toRun, _ref2;
      if (cont == null) {
        cont = (function() {});
      }
      if (_.isFunction(limit)) {
        _ref2 = [limit, null], cont = _ref2[0], limit = _ref2[1];
      }
      path = this.adjustPath(path);
      toRun = this.clone();
      if (!_.include(toRun.views, path)) {
        toRun.views.push(path);
      }
      req = {
        query: toRun.toXML(),
        summaryPath: path,
        format: 'jsonrows'
      };
      if (limit) {
        req.size = limit;
      }
      if (term) {
        req.filterTerm = term;
      }
      parse = function(data) {
        return Deferred(function() {
          var results, stats, _ref3;
          results = data.results.map(function(x) {
            x.count = parseInt(x.count, 10);
            return x;
          });
          stats = {
            uniqueValues: data.uniqueValues
          };
          if ((((_ref3 = results[0]) != null ? _ref3.max : void 0) != null)) {
            _.extend(stats, results[0]);
          }
          return this.resolve(results, stats, data.filteredCount);
        });
      };
      return this.service.post('query/results', req).pipe(parse).done(cont);
    };

    Query.prototype.clone = function(cloneEvents) {
      var cloned;
      cloned = new Query(this, this.service);
      if (cloneEvents) {
        cloned._callbacks = this._callbacks;
      } else {
        cloned._callbacks = {};
      }
      return cloned;
    };

    Query.prototype.next = function() {
      var clone;
      clone = this.clone();
      if (this.maxRows) {
        clone.start = this.start + this.maxRows;
      }
      return clone;
    };

    Query.prototype.previous = function() {
      var clone;
      clone = this.clone();
      if (this.maxRows) {
        clone.start = this.start - this.maxRows;
      } else {
        clone.start = 0;
      }
      return clone;
    };

    Query.prototype.getSortDirection = function(path) {
      var dir, so, _i, _len, _ref2;
      path = this.adjustPath(path);
      _ref2 = this.sortOrder;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        so = _ref2[_i];
        if (so.path === path) {
          dir = so.direction;
        }
      }
      return dir;
    };

    Query.prototype.isOuterJoined = function(path) {
      path = this.adjustPath(path);
      return _.any(this.joins, function(d, p) {
        return d === 'OUTER' && path.indexOf(p) === 0;
      });
    };

    Query.prototype.getOuterJoin = function(path) {
      var joinPaths,
        _this = this;
      path = this.adjustPath(path);
      joinPaths = _.sortBy(_.keys(this.joins), get('length')).reverse();
      return _.find(joinPaths, function(p) {
        return _this.joins[p] === 'OUTER' && path.indexOf(p) === 0;
      });
    };

    Query.prototype._parse_sort_order = function(input) {
      var k, so, v;
      so = input;
      if (_.isString(input)) {
        so = {
          path: input,
          direction: 'ASC'
        };
      } else if (!(input.path != null)) {
        k = _.keys(input)[0];
        v = _.values(input)[0];
        so = {
          path: k,
          direction: v
        };
      }
      so.path = this.adjustPath(so.path);
      so.direction = so.direction.toUpperCase();
      return so;
    };

    Query.prototype.addOrSetSortOrder = function(so) {
      var currentDirection, oe, _i, _len, _ref2;
      so = this._parse_sort_order(so);
      currentDirection = this.getSortDirection(so.path);
      if (!(currentDirection != null)) {
        return this.addSortOrder(so);
      } else if (currentDirection !== so.direction) {
        _ref2 = this.sortOrder;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          oe = _ref2[_i];
          if (oe.path === so.path) {
            oe.direction = so.direction;
          }
        }
        return this.trigger('change:sortorder', this.sortOrder);
      }
    };

    Query.prototype.addSortOrder = function(so) {
      this.sortOrder.push(this._parse_sort_order(so));
      this.trigger('add:sortorder', so);
      return this.trigger('change:sortorder', this.sortOrder);
    };

    Query.prototype.orderBy = function(oes) {
      var oe, _i, _len;
      this.sortOrder = [];
      for (_i = 0, _len = oes.length; _i < _len; _i++) {
        oe = oes[_i];
        this.addSortOrder(oe);
      }
      return this.trigger('set:sortorder', this.sortOrder);
    };

    Query.prototype.addJoins = function(joins) {
      var j, k, v, _i, _len, _results, _results1;
      if (_.isArray(joins)) {
        _results = [];
        for (_i = 0, _len = joins.length; _i < _len; _i++) {
          j = joins[_i];
          _results.push(this.addJoin(j));
        }
        return _results;
      } else {
        _results1 = [];
        for (k in joins) {
          v = joins[k];
          _results1.push(this.addJoin({
            path: k,
            style: v
          }));
        }
        return _results1;
      }
    };

    Query.prototype.addJoin = function(join) {
      var _ref2, _ref3, _ref4;
      if (_.isString(join)) {
        join = {
          path: join,
          style: 'OUTER'
        };
      }
      join.path = this.adjustPath(join.path);
      join.style = (_ref2 = (_ref3 = join.style) != null ? _ref3.toUpperCase() : void 0) != null ? _ref2 : join.style;
      if (_ref4 = join.style, __indexOf.call(Query.JOIN_STYLES, _ref4) < 0) {
        throw new Error("Invalid join style: " + join.style);
      }
      this.joins[join.path] = join.style;
      return this.trigger('set:join', join.path, join.style);
    };

    Query.prototype.setJoinStyle = function(path, style) {
      if (style == null) {
        style = 'OUTER';
      }
      path = this.adjustPath(path);
      style = style.toUpperCase();
      if (this.joins[path] !== style) {
        this.joins[path] = style;
        this.trigger('change:joins', {
          path: path,
          style: style
        });
      }
      return this;
    };

    Query.prototype.addConstraints = function(constraints) {
      var c, con, path, _fn, _i, _len,
        _this = this;
      this.__silent__ = true;
      if (_.isArray(constraints)) {
        for (_i = 0, _len = constraints.length; _i < _len; _i++) {
          c = constraints[_i];
          this.addConstraint(c);
        }
      } else {
        _fn = function(path, con) {
          return _this.addConstraint(interpretConstraint(path, con));
        };
        for (path in constraints) {
          con = constraints[path];
          _fn(path, con);
        }
      }
      this.__silent__ = false;
      this.trigger('add:constraint');
      return this.trigger('change:constraints');
    };

    Query.prototype.addConstraint = function(constraint) {
      if (_.isArray(constraint)) {
        constraint = interpretConArray(constraint);
      }
      constraint.path = this.adjustPath(constraint.path);
      if (constraint.type == null) {
        try {
          constraint.op = get_canonical_op(constraint.op);
        } catch (error) {
          throw new Error("Illegal operator: " + constraint.op);
        }
      }
      this.constraints.push(constraint);
      if ((this.constraintLogic != null) && this.constraintLogic !== '') {
        this.constraintLogic = "(" + this.constraintLogic + ") and " + CODES[this.constraints.length];
      }
      if (!this.__silent__) {
        this.trigger('add:constraint', constraint);
        this.trigger('change:constraints');
      }
      return this;
    };

    Query.prototype.getSorting = function() {
      var oe;
      return ((function() {
        var _i, _len, _ref2, _results;
        _ref2 = this.sortOrder;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          oe = _ref2[_i];
          _results.push("" + oe.path + " " + oe.direction);
        }
        return _results;
      }).call(this)).join(' ');
    };

    Query.prototype.getConstraintXML = function() {
      if (this.constraints.length) {
        return concatMap(conStr)(concatMap(id)(partition(function(c) {
          return c.type != null;
        })(this.constraints)));
      } else {
        return '';
      }
    };

    Query.prototype.getJoinXML = function() {
      var p, s, strs;
      strs = (function() {
        var _ref2, _results;
        _ref2 = this.joins;
        _results = [];
        for (p in _ref2) {
          s = _ref2[p];
          if (this.isInQuery(p) && s === 'OUTER') {
            _results.push("<join path=\"" + p + "\" style=\"OUTER\"/>");
          }
        }
        return _results;
      }).call(this);
      return strs.join('');
    };

    Query.prototype.toXML = function() {
      var attrs, headAttrs, k, v;
      attrs = {
        model: this.model.name,
        view: this.views.join(' '),
        sortOrder: this.getSorting(),
        constraintLogic: this.constraintLogic
      };
      if (this.name != null) {
        attrs.name = this.name;
      }
      headAttrs = ((function() {
        var _results;
        _results = [];
        for (k in attrs) {
          v = attrs[k];
          if (v) {
            _results.push(k + '="' + v + '"');
          }
        }
        return _results;
      })()).join(' ');
      return "<query " + headAttrs + " >" + (this.getJoinXML()) + (this.getConstraintXML()) + "</query>";
    };

    Query.prototype.fetchCode = function(lang, cb) {
      var req;
      req = {
        query: this.toXML(),
        lang: lang
      };
      return this.service.get('query/code', req).pipe(this.service.VERIFIER).pipe(get('code')).done(cb);
    };

    Query.prototype.save = function(name, cb) {
      var req,
        _this = this;
      if (name != null) {
        this.name = name;
      }
      req = {
        data: this.toXML(),
        contentType: "application/xml; charset=UTF-8",
        url: this.service.root + 'query',
        type: 'POST',
        dataType: 'json'
      };
      return this.service.doReq(req).pipe(this.service.VERIFIER).pipe(get('name')).done(cb, function(name) {
        return _this.name = name;
      });
    };

    Query.prototype.getCodeURI = function(lang) {
      var req, _ref2;
      req = {
        query: this.toXML(),
        lang: lang,
        format: 'text'
      };
      if (((_ref2 = this.service) != null ? _ref2.token : void 0) != null) {
        req.token = this.service.token;
      }
      return "" + this.service.root + "query/code?" + (toQueryString(req));
    };

    Query.prototype.getExportURI = function(format) {
      var req, _ref2;
      if (format == null) {
        format = 'tab';
      }
      if (__indexOf.call(Query.BIO_FORMATS, format) >= 0) {
        return this["get" + (format.toUpperCase()) + "URI"]();
      }
      req = {
        query: this.toXML(),
        format: format
      };
      if (((_ref2 = this.service) != null ? _ref2.token : void 0) != null) {
        req.token = this.service.token;
      }
      return "" + this.service.root + "query/results?" + (toQueryString(req));
    };

    Query.prototype.__bio_req = function(types, n) {
      var olds, toRun,
        _this = this;
      toRun = this.clone();
      olds = toRun.views;
      toRun.views = take(n)(olds.map(function(v) {
        return _this.getPathInfo(v).getParent();
      }).filter(function(p) {
        return _.any(types, function(t) {
          return p.isa(t);
        });
      }).map(function(p) {
        return p.append('primaryIdentifier').toPathString();
      }));
      return {
        query: toRun.toXML(),
        format: 'text'
      };
    };

    Query.prototype._fasta_req = function() {
      return this.__bio_req(["SequenceFeature", 'Protein'], 1);
    };

    Query.prototype._gff3_req = function() {
      return this.__bio_req(['SequenceFeature']);
    };

    Query.prototype._bed_req = Query.prototype._gff3_req;

    return Query;

  })();

  Query.ATTRIBUTE_OPS = _.union(Query.ATTRIBUTE_VALUE_OPS, Query.MULTIVALUE_OPS, Query.NULL_OPS);

  Query.REFERENCE_OPS = _.union(Query.TERNARY_OPS, Query.LOOP_OPS, Query.LIST_OPS);

  _ref2 = Query.BIO_FORMATS;
  _fn = function(f) {
    var getMeth, reqMeth, uriMeth;
    reqMeth = "_" + f + "_req";
    getMeth = "get" + (f.toUpperCase());
    uriMeth = getMeth + "URI";
    Query.prototype[getMeth] = function(cb) {
      var req;
      if (cb == null) {
        cb = function() {};
      }
      req = this[reqMeth]();
      return this.service.post('query/results/' + f, req).done(cb);
    };
    return Query.prototype[uriMeth] = function(cb) {
      var req, _ref3;
      req = this[reqMeth]();
      if (((_ref3 = this.service) != null ? _ref3.token : void 0) != null) {
        req.token = this.service.token;
      }
      return "" + this.service.root + "query/results/" + f + "?" + (toQueryString(req));
    };
  };
  for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
    f = _ref2[_i];
    _fn(f);
  }

  _get_data_fetcher = function(server_fn) {
    return function() {
      var cbs, page, x, _ref3;
      page = arguments[0], cbs = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (this.service[server_fn]) {
        if (!(page != null)) {
          page = {};
        } else if (_.isFunction(page)) {
          page = {};
          cbs = (function() {
            var _j, _len1, _results;
            _results = [];
            for (_j = 0, _len1 = arguments.length; _j < _len1; _j++) {
              x = arguments[_j];
              _results.push(x);
            }
            return _results;
          }).apply(this, arguments);
        }
        _.defaults(page, {
          start: this.start,
          size: this.maxRows
        });
        return (_ref3 = this.service)[server_fn].apply(_ref3, [this, page].concat(__slice.call(cbs)));
      } else {
        throw new Error("Service does not provide '" + server_fn + "'.");
      }
    };
  };

  for (_j = 0, _len1 = RESULTS_METHODS.length; _j < _len1; _j++) {
    mth = RESULTS_METHODS[_j];
    Query.prototype[mth] = _get_data_fetcher(mth);
  }

  intermine.Query = Query;

}).call(this);

(function() {
  var $, DEFAULT_ERROR_HANDLER, DEFAULT_PROTOCOL, Deferred, ENRICHMENT_PATH, HAS_PROTOCOL, HAS_SUFFIX, IDENTITY, IDResolutionJob, IS_NODE, LISTS_PATH, LIST_OPERATION_PATHS, LIST_PIPE, List, MODELS, MODEL_PATH, Model, PATH_VALUES_PATH, PREF_PATH, QUERY_RESULTS_PATH, QUICKSEARCH_PATH, Query, REQUIRES_VERSION, SUBTRACT_PATH, SUFFIX, SUMMARYFIELDS_PATH, SUMMARY_FIELDS, Service, TABLE_ROW_PATH, TEMPLATES_PATH, TO_NAMES, User, VERSIONS, VERSION_PATH, WHOAMI_PATH, WIDGETS, WIDGETS_PATH, WITH_OBJ_PATH, curry, dejoin, error, fold, funcutils, get, getListFinder, http, intermine, invoke, jQuery, set, success, to_query_string, _, __root__, _get_or_fetch,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  IS_NODE = typeof exports !== 'undefined';

  __root__ = typeof exports !== "undefined" && exports !== null ? exports : this;

  if (IS_NODE) {
    _ = require('underscore')._;
    Deferred = ($ = require('underscore.deferred')).Deferred;
    Model = require('./model').Model;
    Query = require('./query').Query;
    List = require('./lists').List;
    User = require('./user').User;
    IDResolutionJob = require('./id-resolution-job').IDResolutionJob;
    funcutils = require('./util');
    to_query_string = require('querystring').stringify;
    http = require('./http');
    intermine = exports;
  } else {
    _ = __root__._, jQuery = __root__.jQuery, intermine = __root__.intermine;
    Deferred = ($ = jQuery).Deferred;
    to_query_string = function(obj) {
      return jQuery.param(obj, true);
    };
    Model = intermine.Model, Query = intermine.Query, List = intermine.List, User = intermine.User, IDResolutionJob = intermine.IDResolutionJob, funcutils = intermine.funcutils, http = intermine.http;
  }

  curry = funcutils.curry, fold = funcutils.fold, get = funcutils.get, set = funcutils.set, invoke = funcutils.invoke, success = funcutils.success, error = funcutils.error, REQUIRES_VERSION = funcutils.REQUIRES_VERSION, dejoin = funcutils.dejoin;

  VERSIONS = {};

  MODELS = {};

  SUMMARY_FIELDS = {};

  WIDGETS = {};

  DEFAULT_PROTOCOL = "http://";

  VERSION_PATH = "version";

  TEMPLATES_PATH = "templates";

  LISTS_PATH = "lists";

  MODEL_PATH = "model";

  SUMMARYFIELDS_PATH = "summaryfields";

  QUERY_RESULTS_PATH = "query/results";

  QUICKSEARCH_PATH = "search";

  WIDGETS_PATH = "widgets";

  ENRICHMENT_PATH = "list/enrichment";

  WITH_OBJ_PATH = "listswithobject";

  LIST_OPERATION_PATHS = {
    union: "lists/union",
    intersection: "lists/intersect",
    difference: "lists/diff"
  };

  SUBTRACT_PATH = 'lists/subtract';

  WHOAMI_PATH = "user/whoami";

  TABLE_ROW_PATH = QUERY_RESULTS_PATH + '/tablerows';

  PREF_PATH = 'user/preferences';

  PATH_VALUES_PATH = 'path/values';

  IDENTITY = function(x) {
    return x;
  };

  HAS_PROTOCOL = /^https?:\/\//i;

  HAS_SUFFIX = /service\/?$/i;

  SUFFIX = "/service/";

  DEFAULT_ERROR_HANDLER = function(e) {
    var args, _ref;
    if (IS_NODE && (e.stack != null)) {
      return console.error(e.stack);
    } else {
      args = (e != null ? e.stack : void 0) ? [e.stack] : arguments;
      if (typeof console !== "undefined" && console !== null) {
        return (_ref = console.error || console.log) != null ? _ref.apply(console, args) : void 0;
      }
    }
  };

  _get_or_fetch = function(propName, store, path, key, cb) {
    var prop, value, _ref,
      _this = this;
    prop = (_ref = this[propName]) != null ? _ref : this[propName] = this.useCache && (value = store[this.root]) ? success(value) : this.get(path).pipe(get(key)).done(function(x) {
      return store[_this.root] = x;
    });
    return prop.done(cb);
  };

  getListFinder = function(name) {
    return function(lists) {
      return Deferred(function() {
        var list;
        if (list = _.find(lists, function(l) {
          return l.name === name;
        })) {
          return this.resolve(list);
        } else {
          return this.reject("List \"" + name + "\" not found among: " + (lists.map(get('name'))));
        }
      });
    };
  };

  LIST_PIPE = function(service, prop) {
    if (prop == null) {
      prop = 'listName';
    }
    return _.compose(service.fetchList, get(prop));
  };

  TO_NAMES = function(xs) {
    var x, _i, _len, _ref, _ref1, _results;
    if (xs == null) {
      xs = [];
    }
    _ref = (_.isArray(xs) ? xs : [xs]);
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      x = _ref[_i];
      _results.push((_ref1 = x.name) != null ? _ref1 : x);
    }
    return _results;
  };

  Service = (function() {

    function Service(_arg) {
      var loc, noCache, _ref, _ref1,
        _this = this;
      this.root = _arg.root, this.token = _arg.token, this.errorHandler = _arg.errorHandler, this.DEBUG = _arg.DEBUG, this.help = _arg.help, noCache = _arg.noCache;
      this.createList = __bind(this.createList, this);

      this.resolveIds = __bind(this.resolveIds, this);

      this.query = __bind(this.query, this);

      this.fetchWidgetMap = __bind(this.fetchWidgetMap, this);

      this.fetchWidgets = __bind(this.fetchWidgets, this);

      this.complement = __bind(this.complement, this);

      this.fetchListsContaining = __bind(this.fetchListsContaining, this);

      this.fetchList = __bind(this.fetchList, this);

      this.findLists = __bind(this.findLists, this);

      this.fetchLists = __bind(this.fetchLists, this);

      this.fetchTemplates = __bind(this.fetchTemplates, this);

      this.tableRows = __bind(this.tableRows, this);

      this.rows = __bind(this.rows, this);

      this.records = __bind(this.records, this);

      this.table = __bind(this.table, this);

      this.pathValues = __bind(this.pathValues, this);

      this.values = __bind(this.values, this);

      this.fetchUser = __bind(this.fetchUser, this);

      this.whoami = __bind(this.whoami, this);

      this.findById = __bind(this.findById, this);

      this.count = __bind(this.count, this);

      this.enrichment = __bind(this.enrichment, this);

      if (this.root == null) {
        throw new Error("No service root provided. This is required");
      }
      if (!HAS_PROTOCOL.test(this.root)) {
        this.root = DEFAULT_PROTOCOL + this.root;
      }
      if (!HAS_SUFFIX.test(this.root)) {
        this.root = this.root + SUFFIX;
      }
      this.root = this.root.replace(/ice$/, "ice/");
      if ((_ref = this.errorHandler) == null) {
        this.errorHandler = DEFAULT_ERROR_HANDLER;
      }
      if ((_ref1 = this.help) == null) {
        this.help = 'no.help.available@dev.null';
      }
      this.useCache = !noCache;
      loc = IS_NODE ? '' : location.protocol + '//' + location.host;
      this.getFormat = function(intended) {
        if (intended == null) {
          intended = 'json';
        }
        if (!/jsonp/.test(intended)) {
          if (!(IS_NODE || jQuery.support.cors)) {
            if (loc.substring(0, _this.root.length) !== _this.root) {
              return intended.replace('json', 'jsonp');
            }
          }
        }
        return intended;
      };
    }

    Service.prototype.post = function(path, data) {
      if (data == null) {
        data = {};
      }
      return this.makeRequest('POST', path, data);
    };

    Service.prototype.get = function(path, data) {
      return this.makeRequest('GET', path, data);
    };

    Service.prototype.makeRequest = function(method, path, data, cb, indiv) {
      var errBack, opts, url, _ref, _ref1;
      if (method == null) {
        method = 'GET';
      }
      if (path == null) {
        path = '';
      }
      if (data == null) {
        data = {};
      }
      if (cb == null) {
        cb = (function() {});
      }
      if (indiv == null) {
        indiv = false;
      }
      if (_.isArray(cb)) {
        _ref = cb, cb = _ref[0], errBack = _ref[1];
      }
      if (_.isArray(data)) {
        data = _.foldl(data, (function(m, _arg) {
          var k, v;
          k = _arg[0], v = _arg[1];
          m[k] = v;
          return m;
        }), {});
      }
      url = this.root + path;
      if (errBack == null) {
        errBack = this.errorHandler;
      }
      if (this.token) {
        data.token = this.token;
      }
      data.format = this.getFormat(data.format);
      if (/jsonp/.test(data.format)) {
        data.method = method;
        method = 'GET';
        url += '?callback=?';
      }
      if (!http.supports(method)) {
        _ref1 = [method, http.getMethod(method)], data.method = _ref1[0], method = _ref1[1];
      }
      if (method === 'DELETE') {
        url += '?' + to_query_string(data);
      }
      opts = {
        data: data,
        dataType: data.format,
        success: cb,
        error: errBack,
        url: url,
        type: method
      };
      return http.doReq(opts, indiv);
    };

    Service.prototype.enrichment = function(opts, cb) {
      var _this = this;
      return REQUIRES_VERSION(this, 8, function() {
        return _this.get(ENRICHMENT_PATH, _.defaults({}, opts, {
          maxp: 0.05,
          correction: 'Holm-Bonferroni'
        })).pipe(get('results')).done(cb);
      });
    };

    Service.prototype.search = function(options, cb) {
      var _this = this;
      if (options == null) {
        options = {};
      }
      if (cb == null) {
        cb = (function() {});
      }
      return REQUIRES_VERSION(this, 9, function() {
        var k, parse, req, v, _ref, _ref1;
        if (_.isFunction(options)) {
          _ref = [options, {}], cb = _ref[0], options = _ref[1];
        }
        if (_.isString(options)) {
          options = {
            q: options
          };
        }
        req = _.defaults({}, options, {
          q: ''
        });
        delete req.facets;
        if (options.facets) {
          _ref1 = options.facets;
          for (k in _ref1) {
            v = _ref1[k];
            req["facet_" + k] = v;
          }
        }
        parse = function(response) {
          return success(response.results, response.facets);
        };
        return _this.post(QUICKSEARCH_PATH, req).pipe(parse).done(cb);
      });
    };

    Service.prototype.count = function(q, cb) {
      var p, req;
      if (cb == null) {
        cb = (function() {});
      }
      if (!q) {
        return error("Not enough arguments");
      } else if (q.toPathString != null) {
        p = q.isClass() ? q.append('id') : q;
        return this.pathValues(p, 'count').done(cb);
      } else if (q.toXML != null) {
        req = {
          query: q.toXML(),
          format: 'jsoncount'
        };
        return this.post(QUERY_RESULTS_PATH, req).pipe(get('count')).done(cb);
      } else if (_.isString(q)) {
        return this.fetchModel().pipe(invoke('makePath', q.replace(/\.\*$/, '.id'))).pipe(this.count).done(cb);
      } else {
        return this.query(q).pipe(this.count).done(cb);
      }
    };

    Service.prototype.findById = function(type, id, cb) {
      return this.query({
        from: type,
        select: ['**'],
        where: {
          id: id
        }
      }).pipe(dejoin).pipe(invoke('records')).pipe(get(0)).done(cb);
    };

    Service.prototype.find = function(type, term, cb) {
      return this.query({
        from: type,
        select: ['**'],
        where: [[type, 'LOOKUP', term]]
      }).pipe(dejoin).pipe(invoke('records')).done(cb);
    };

    Service.prototype.whoami = function(cb) {
      var _this = this;
      return REQUIRES_VERSION(this, 9, function() {
        return _this.get(WHOAMI_PATH).pipe(get('user')).pipe(function(x) {
          return new User(_this, x);
        }).done(cb);
      });
    };

    Service.prototype.fetchUser = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.whoami.apply(this, args);
    };

    Service.prototype.values = function(path, typeConstraints, cb) {
      var _this = this;
      if (typeConstraints == null) {
        typeConstraints = {};
      }
      if (cb == null) {
        cb = (function() {});
      }
      return REQUIRES_VERSION(this, 6, function() {
        try {
          return _this.fetchModel().pipe(invoke('makePath', path, path.subclasses || typeConstraints)).pipe(_this.pathValues).done(cb);
        } catch (e) {
          return error(e);
        }
      });
    };

    Service.prototype.pathValues = function(path, wanted) {
      var format, req;
      if (wanted !== 'count') {
        wanted = 'results';
      }
      format = wanted === 'count' ? 'jsoncount' : 'json';
      req = {
        format: format,
        path: path.toString(),
        typeConstraints: JSON.stringify(path.subclasses)
      };
      return this.post(PATH_VALUES_PATH, req).pipe(get(wanted));
    };

    Service.prototype.doPagedRequest = function(q, path, page, format, cb) {
      var req,
        _this = this;
      if (page == null) {
        page = {};
      }
      if (q.toXML != null) {
        req = _.defaults({}, {
          query: q.toXML(),
          format: format
        }, page);
        return this.post(path, req).pipe(function(resp) {
          return success(resp.results, resp);
        }).done(cb);
      } else {
        return this.query(q).pipe(function(query) {
          return _this.doPagedRequest(query, path, page, format, cb);
        });
      }
    };

    Service.prototype.table = function(q, page, cb) {
      return this.doPagedRequest(q, QUERY_RESULTS_PATH, page, 'jsontable', cb);
    };

    Service.prototype.records = function(q, page, cb) {
      return this.doPagedRequest(q, QUERY_RESULTS_PATH, page, 'jsonobjects', cb);
    };

    Service.prototype.rows = function(q, page, cb) {
      return this.doPagedRequest(q, QUERY_RESULTS_PATH, page, 'json', cb);
    };

    Service.prototype.tableRows = function(q, page, cb) {
      return this.doPagedRequest(q, TABLE_ROW_PATH, page, 'json', cb);
    };

    Service.prototype.fetchTemplates = function(cb) {
      return this.get(TEMPLATES_PATH).pipe(get('templates')).done(cb);
    };

    Service.prototype.fetchLists = function(cb) {
      return this.findLists('', cb);
    };

    Service.prototype.findLists = function(name, cb) {
      var _this = this;
      if (name == null) {
        name = '';
      }
      if (cb == null) {
        cb = (function() {});
      }
      return this.fetchVersion().pipe(function(v) {
        var fn;
        if (name && v < 13) {
          return error("Finding lists by name on the server requires version 13. This is only " + v);
        } else {
          fn = function(ls) {
            var data, _i, _len, _results;
            _results = [];
            for (_i = 0, _len = ls.length; _i < _len; _i++) {
              data = ls[_i];
              _results.push(new List(data, _this));
            }
            return _results;
          };
          return _this.get(LISTS_PATH, {
            name: name
          }).pipe(get('lists')).pipe(fn).done(cb);
        }
      });
    };

    Service.prototype.fetchList = function(name, cb) {
      var _this = this;
      return this.fetchVersion().pipe(function(v) {
        if (v < 13) {
          return _this.findLists().pipe(getListFinder(name)).done(cb);
        } else {
          return _this.findLists(name).pipe(get(0)).done(cb);
        }
      });
    };

    Service.prototype.fetchListsContaining = function(opts, cb) {
      var fn,
        _this = this;
      fn = function(xs) {
        var x, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = xs.length; _i < _len; _i++) {
          x = xs[_i];
          _results.push(new List(x, _this));
        }
        return _results;
      };
      return this.get(WITH_OBJ_PATH, opts).pipe(get('lists')).pipe(fn).done(cb);
    };

    Service.prototype.combineLists = function(operation, options, cb) {
      var req, _ref;
      req = _.pick(options, 'name', 'description');
      if ((_ref = req.description) == null) {
        req.description = "" + operation + " of " + (options.lists.join(', '));
      }
      req.tags = (options.tags || []).join(';');
      req.lists = (options.lists || []).join(';');
      return this.get(LIST_OPERATION_PATHS[operation], req).pipe(LIST_PIPE(this)).done(cb);
    };

    Service.prototype.merge = function() {
      return this.combineLists.apply(this, ['union'].concat(__slice.call(arguments)));
    };

    Service.prototype.intersect = function() {
      return this.combineLists.apply(this, ['intersection'].concat(__slice.call(arguments)));
    };

    Service.prototype.diff = function() {
      return this.combineLists.apply(this, ['difference'].concat(__slice.call(arguments)));
    };

    Service.prototype.complement = function(options, cb) {
      var defaultDesc, description, exclude, from, lists, name, references, req, tags;
      if (options == null) {
        options = {};
      }
      if (cb == null) {
        cb = function() {};
      }
      from = options.from, exclude = options.exclude, name = options.name, description = options.description, tags = options.tags;
      defaultDesc = function() {
        return "Relative complement of " + (lists.join(' and ')) + " in " + (references.join(' and '));
      };
      references = TO_NAMES(from);
      lists = TO_NAMES(exclude);
      if (name == null) {
        name = defaultDesc();
      }
      if (description == null) {
        description = defaultDesc();
      }
      if (tags == null) {
        tags = [];
      }
      req = {
        name: name,
        description: description,
        tags: tags,
        lists: lists,
        references: references
      };
      return this.post(SUBTRACT_PATH, req).pipe(LIST_PIPE(this)).done(cb);
    };

    Service.prototype.fetchWidgets = function(cb) {
      var _this = this;
      return REQUIRES_VERSION(this, 8, function() {
        return _get_or_fetch.call(_this, 'widgets', WIDGETS, WIDGETS_PATH, 'widgets', cb);
      });
    };

    Service.prototype.fetchWidgetMap = function(cb) {
      var _this = this;
      return REQUIRES_VERSION(this, 8, function() {
        var toMap, _ref;
        toMap = fold({}, function(m, w) {
          m[w.name] = w;
          return m;
        });
        return ((_ref = _this.__wmap__) != null ? _ref : _this.__wmap__ = _this.fetchWidgets().then(toMap)).done(cb);
      });
    };

    Service.prototype.fetchModel = function(cb) {
      return _get_or_fetch.call(this, 'model', MODELS, MODEL_PATH, 'model').pipe(Model.load).pipe(set({
        service: this
      })).done(cb);
    };

    Service.prototype.fetchSummaryFields = function(cb) {
      return _get_or_fetch.call(this, 'summaryFields', SUMMARY_FIELDS, SUMMARYFIELDS_PATH, 'classes', cb);
    };

    Service.prototype.fetchVersion = function(cb) {
      return _get_or_fetch.call(this, 'version', VERSIONS, VERSION_PATH, 'version', cb);
    };

    Service.prototype.query = function(options, cb) {
      var _this = this;
      return $.when(this.fetchModel(), this.fetchSummaryFields()).pipe(function(m, sfs) {
        var args, service;
        args = _.defaults({}, options, {
          model: m,
          summaryFields: sfs
        });
        service = _this;
        return Deferred(function() {
          this.fail(service.errorHandler);
          this.done(cb);
          try {
            return this.resolve(new Query(args, service));
          } catch (e) {
            return this.reject(e);
          }
        });
      });
    };

    Service.prototype.manageUserPreferences = function(method, data) {
      var _this = this;
      return REQUIRES_VERSION(this, 11, function() {
        return _this.makeRequest(method, PREF_PATH, data).pipe(get('preferences'));
      });
    };

    Service.prototype.resolveIds = function(opts, cb) {
      var _this = this;
      return REQUIRES_VERSION(this, 10, function() {
        var req;
        req = {
          data: JSON.stringify(opts),
          dataType: 'json',
          url: _this.root + 'ids',
          type: 'POST',
          contentType: 'application/json'
        };
        return http.doReq(req).pipe(get('uid')).pipe(IDResolutionJob.create(_this)).done(cb);
      });
    };

    Service.prototype.createList = function(opts, ids, cb) {
      var adjust, req;
      if (opts == null) {
        opts = {};
      }
      if (ids == null) {
        ids = '';
      }
      if (cb == null) {
        cb = function() {};
      }
      adjust = curry(_.defaults, {
        token: this.token,
        tags: opts.tags || []
      });
      req = {
        data: _.isArray(ids) ? ids.map(function(x) {
          return "\"" + x + "\"";
        }).join("\n") : ids,
        dataType: 'json',
        url: "" + this.root + "lists?" + (to_query_string(adjust(opts))),
        type: 'POST',
        contentType: 'text/plain'
      };
      return http.doReq(req).pipe(LIST_PIPE(this)).done(cb);
    };

    return Service;

  })();

  Service.prototype.rowByRow = http.iterReq('POST', QUERY_RESULTS_PATH, 'json');

  Service.prototype.eachRow = Service.prototype.rowByRow;

  Service.prototype.recordByRecord = http.iterReq('POST', QUERY_RESULTS_PATH, 'jsonobjects');

  Service.prototype.eachRecord = Service.prototype.recordByRecord;

  Service.prototype.union = Service.prototype.merge;

  Service.prototype.difference = Service.prototype.diff;

  Service.prototype.symmetricDifference = Service.prototype.diff;

  Service.prototype.relativeComplement = Service.prototype.complement;

  Service.prototype.subtract = Service.prototype.complement;

  Service.flushCaches = function() {
    MODELS = {};
    VERSIONS = {};
    SUMMARY_FIELDS = {};
    return WIDGETS = {};
  };

  Service.connect = function(opts) {
    if (opts == null) {
      opts = {};
    }
    return new Service(opts);
  };

  intermine.Service = Service;

}).call(this);

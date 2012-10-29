"use strict";

(function(exports, IS_NODE) {

    var _;
    var TAGS_PATH = "list/tags";
    if (IS_NODE) {
        _ = require('underscore')._;
    } else {
        _ = exports._;
        if (typeof exports.intermine == 'undefined') {
            exports.intermine = {};
        }
        exports = intermine;
    }

    var isFolder = function(t) {
        return t.substr(0, t.indexOf(":")) === '__folder__';
    };
    var getFolderName = function(t) {
        return t.substr(t.indexOf(":") + 1);
    };

    var List = function(properties, service) {

        _(this).extend(properties);
        this.service = service;
        this.dateCreated = this.dateCreated ? new Date(this.dateCreated) : null;

        this.folders = _(this.tags).chain()
                                   .filter(isFolder)
                                   .map(getFolderName)
                                   .value();

        /**
         * Does this list have a given tag?
         *
         * @param t the tag this list may or may not have
         * @return Boolean whether or not this list has a given tag.
         */
        this.hasTag = function(t) {
            return _(this.tags).include(t);
        };

        /**
         * Delete this list. 
         *
         * The list MUST not be used after this function has been called.
         * @param cb a function to call upon completion of this action
         * @return jQuery.Deferred
         */
        this.del = function(cb) {
            cb = cb || function() {};
            return this.service.makeRequest("lists", 
                {name: this.name}, cb, "DELETE");
        };

        /**
         * Get the contents of this list.
         *
         * Each item in the list will be returned as an object with the summary-fields selected.
         * The results are unordered.
         * @param cb A function (optional) to call on completion of this action (default = no-op)
         * @return jQuery.Deferred
         */
        this.contents = function(cb) {
            cb = cb || function() {};
            var query = {select: ["*"], from: this.type, where: {}};
            query.where[this.type] = {IN: this.name};
            return this.service.query(query, function(q) {
                q.records(cb);
            });
        };

        /**
         * Get enrichment statistics for this list.
         *
         * @see intermine.service#enrichment
         * @param data A map of key-value terms with the following keys: 'widget', 'maxp', 'correction', and optionally 'filter' and 'population'.
         * @param cb a function of the type [(results) -> void] to call on completion of this request.
         * @return jQuery.Deferred
         */
        this.enrichment = function(data, cb) {
            data.list = this.name;
            return this.service.enrichment(data, cb);
        };

        this.shareWithUser = function(recipient, cb) {
            var data = {list: this.name, with: recipient};
            return this.service.makeRequest("lists/shares", data, cb, "POST");
        };

        this.inviteUserToShare = function(recipient, cb) {
            var data = {list: this.name, to: recipient, notify: true};
            return this.service.makeRequest("lists/invitations", data, cb, "POST");
        };

    };

    exports.List = List;
}).call(this, typeof exports === 'undefined' ? this : exports, typeof exports != 'undefined');
        

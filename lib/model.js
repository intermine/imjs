"use strict";

(function(exports, IS_NODE) {

    /**
     * A module for encapsulating the metadata available to a
     * client.
     * @module intermine/Model
     */

    var _, Deferred, PathInfo;
    if (IS_NODE) {
        _ = require('underscore')._;
        Deferred = require('underscore.deferred').Deferred;
        PathInfo = require('./path').PathInfo;
    } else {
        _ = exports._;
        Deferred = exports.jQuery.Deferred;
        if (typeof exports.intermine === 'undefined') {
            exports.intermine = {};
        }
        PathInfo = exports.PathInfo;
        exports = exports.intermine;
    } 

    var Table = function(o) {
        _(this).extend(o);
        _(this.collections).each(function(coll) {
            coll.isCollection = true;
        });
        this.fields = _({}).extend(this.attributes, this.references, this.collections);
        this.allReferences = _({}).extend(this.references, this.collections);
    };

    Table.prototype = {
        constructor: Table
    };

    Table.prototype.toString = function toString() {
        return "[Table name=" + this.name + "]"
    };

    var Model = function(model) {
        _(this).extend(model);

        // Promote classes to tables.
        var classes = this.classes;
        _(classes).each(function(cd, name) {
            classes[name] = new Table(cd);
        });

    };

    Model.prototype.constructor = Model;

    /**
    * Get the ClassDescriptor for a path. If the path is a root-path, it 
    * returns the class descriptor for the class named, otherwise it returns 
    * the class the last part resolves to. If the last part is an attribute, this
    * function returns "undefined".
    *
    * @param path The path to resolve.
    * @return A class descriptor object, or undefined.
    */
    Model.prototype.getCdForPath = function(path) {
        var parts = path.split(".");
        var cd = this.classes[parts.shift()];
        return _(parts).reduce(_(function (memo, fieldName) {
            var fields = _({}).extend(
                memo.attributes, memo.references, memo.collections);
            return this.classes[fields[fieldName].referencedType];
        }).bind(this), cd);
    };

    /**
    * Get an object describing the path defined by the arguments.
    *
    * @param path The path to be described.
    * @param subclasses An object mapping path {Str} -> type {Str}
    */
    Model.prototype.getPathInfo = function(path, subclasses) {
        return PathInfo.parse(this, path, subclasses);
    };

    // TODO: write unit tests.
    // TODO - move all uses to PathInfo
    /**
        * Determine if there are any collections mentioned in the given path. 
        * eg: 
        *   Department.employees.name -> true
        *   Department.company.name -> false
        *
        * @param path {String} The path to examine.
        * @return {Boolean} Whether or not there is any collection in the path.
        */
    Model.prototype.hasCollection = function(path) {
        var paths = []
            ,parts = path.split(".")
            ,bit, parent, cd;
        while (bit = parts.pop()) {
            parent = parts.join(".");
            if ((parent) && (cd = this.getCdForPath(parent))) {
                if (cd.collections[bit]) {
                    return true;
                }
            }
        }
        return false;
    };

    var _subclass_map = {};

    /**
        * Return the subclasses of a given class. The subclasses of a class
        * includes the class itself, and is thus equivalent to 
        * 'isAssignableTo' in java.
        */
    Model.prototype.getSubclassesOf = function(cls) {
        var self = this;
        if (cls in _subclass_map) {
            return _subclass_map[cls];
        }
        var ret = [cls];
        _(this.classes).each(function(c) {
            if (_(c["extends"]).include(cls)) {
                ret = ret.concat(self.getSubclassesOf(c.name));
            }
        });
        _subclass_map[cls] = ret;
        return ret;
    };

    /**
    * Get the full ancestry of a particular class.
    *
    * The returned ancestry never includes the root InterMineObject base class.
    */
    Model.prototype.getAncestorsOf = function(clazz) {
        clazz = (clazz && clazz.name) ? clazz : this.classes[clazz + ""];
        var ancestors = clazz["extends"].slice();
        _(ancestors).each(_(function(a) {
            if (!a.match(/InterMineObject$/)) {
                ancestors = _.union(ancestors, this.getAncestorsOf(a));
            }
        }).bind(this));
        return ancestors;
    }


    /**
    * Return the common type of two model classes, or null if there isn't one.
    */
    Model.prototype.findCommonTypeOf = function(classA, classB) {
        if (classB == null || classA == null || classA == classB) {
            return classA;
        }
        var allAncestorsOfA = this.getAncestorsOf(classA);
        var allAncestorsOfB = this.getAncestorsOf(classB);
        // If one is a superclass of the other, return it.
        if (_(allAncestorsOfA).include(classB)) {
            return classB;
        }
        if (_(allAncestorsOfB).include(classA)) {
            return classA;
        }
        // Return the first common ancestor

        return _.intersection(allAncestorsOfA, allAncestorsOfB).shift();
    };

    /**
    * Return the common type of 0 or more model classes, or null if there is none.
    *
    * @param model The data model for this service.
    * @classes {String[]} classes the model classes to try and get a common type of.
    */
    Model.prototype.findCommonTypeOfMultipleClasses = function(classes) {
        return _.reduce(classes, _(this.findCommonTypeOf).bind(this), classes.pop());
    };
    Model.NUMERIC_TYPES = ["int", "Integer", "double", "Double", "float", "Float"];
    Model.INTEGRAL_TYPES = ["int", "Integer"]
    Model.BOOLEAN_TYPES = ["boolean", "Boolean"];

    exports.Model = Model;
}).call(this, typeof exports === 'undefined' ? this : exports, typeof exports != 'undefined');


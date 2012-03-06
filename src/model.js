if (typeof intermine == "undefined") {
    intermine = {};
}

if (typeof __ == "undefined") {
    __ = function(x) {return _(x).chain()};
}

_.extend(intermine, (function() {
    var Model = function(model) {

        /**
        * Get the ClassDescriptor for a path. If the path is a root-path, it 
        * returns the class descriptor for the class named, otherwise it returns 
        * the class the last part resolves to. If the last part is an attribute, this
        * function returns "undefined".
        *
        * @param path The path to resolve.
        * @return A class descriptor object, or undefined.
        */
        this.getCdForPath = function(path) {
            var parts = path.split(".");
            var cd = this.classes[parts.shift()];
            return _(parts).reduce(_(function (memo, fieldName) {
                var fields = _({}).extend(
                    memo.attributes, memo.references, memo.collections);
                return this.classes[fields[fieldName].referencedType];
            }).bind(this), cd);
        };

        // TODO: write unit tests.
        /**
         * Get the type of an attribute path. If the path represents a class or a reference, 
         * the class itself is returned, otherwise the name of the attribute type is returned, 
         * minus any "java.lang." prefix.
         *
         * @param path The path to get the type of
         * @return A class-descriptor, or an attribute type name.
         */
        this.getType = function(path) {
            var cd = this.getCdForPath(path);
            if (cd) {
                return cd;
            }
            var parent = path.replace(/\.[^\.]+$/, "");
            var fieldName = path.replace(/.*\./, "");
            cd = this.getCdForPath(parent);
            if (!cd || !cd.attributes[fieldName]) {
                throw "Invalid path: " + path;
            }
            return cd.attributes[fieldName].type.replace(/java.lang./, "");
        };

        // TODO: write unit tests.
        /**
         * Determine if there are any collections mentioned in the given path. 
         * eg: 
         *   Department.employees.name -> true
         *   Department.company.name -> false
         *
         * @param path {String} The path to examine.
         * @return {Boolean} Whether or not there is any collection in the path.
         */
        this.hasCollection = function(path) {
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
        this.getSubclassesOf = function(cls) {
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
        this.getAncestorsOf = function(className) {
            var ancestors = this.classes[className]["extends"].slice();
            _(ancestors).each(_(function(a) {
                if (!a.match(/InterMineObject$/)) {
                    ancestors = _.union(ancestors, this.getAncestorsOf(a));
                }
            }).bind(this));
            return ancestors;
        }

        _(this).extend(model);

        /**
        * Return the common type of two model classes, or null if there isn't one.
        */
        this.findCommonTypeOf = function(classA, classB) {
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
        this.findCommonTypeOfMultipleClasses = function(classes) {
            return _.reduce(classes, _(this.findCommonTypeOf).bind(this), classes.pop());
        };
    };
    Model.NUMERIC_TYPES = ["int", "Integer", "double", "Double", "float", "Float"];
    Model.BOOLEAN_TYPES = ["boolean", "Boolean"];
    return {"Model": Model};
})());


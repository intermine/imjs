(function (window) {
    'use strict';

    if (!window.jQuery) {
        console.log("Dependencies not met. jQuery not found");
        throw new Error("jQuery is missing");
    } else if (!window.QUnit) {
        console.log("Qunit is not loaded");
        throw new Error("QUnit missing");
    } else if (!window.intermine) {
        console.log("imjs not loaded");
        throw new Error("intermine is missing");
    } 

    var Service = window.intermine.Service
      , root    = (window.location.host || "localhost") + "/intermine-test"

    console.log("");
    console.log("Testing against " + root);

    window.TestCase = {
        setup: function () {
            this.succeed = function () {
                ok(true, "Test passed");
            };
            this.fail = function (err) {
                console.error("FAILURE", [].slice.call(arguments, 0)); 
                ok(false, err); 
            };
            this.s = new Service({
                root:  root,
                token: "test-user-token"
            });
            this.flymine = new intermine.Service({
                root: "http://www.flymine.org/query/service"
            });
            this.allEmployees = {
                select: ['*'],
                from: 'Employee'
            };
            this.olderEmployees = {
                select: ['*'],
                from: 'Employee',
                where: { age: {gt: 50} }
            };
            this.youngerEmployees = {
                select: ['*'],
                from: 'Employee',
                where: { age: {le: 50} }
            };
        }
    };

    try {
        var context = new window.TestCase.setup();
        context.s.fetchLists(function (ls) {
            _.each(ls, function (l) {
                if (l.hasTag('qunit')) {
                    l.del();
                }
            });
        });
    } catch (e) {
        console.error("Caught an error");
        // ignore.
    }
})(window);


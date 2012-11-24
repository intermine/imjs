(function () {
    'use strict';

    module("service root", window.TestCase);

    test('Add default elements when missing', function () {
        var host = window.location.host || "localhost";
        equal(this.s.root, "http://" + host + "/intermine-test/service/");
    });

    test('Leaves URLs that look basically OK alone, but adds a final slash', function () {
        equal(this.flymine.root, "http://www.flymine.org/query/service/");
    });
})();

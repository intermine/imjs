(function () {
    var is46 = _.bind(equal, null, 46);

    module("Query Counts", window.TestCase);

    asyncTest('Can count - cb', 1, function () {
        this.s.query(this.olderEmployees, function (q) {
            q.count(is46).always(start);
        });
    });

    asyncTest('Can count all', 2, function () {
        this.s.query(this.allEmployees, function (q) {
            q.count(function (c) {
                ok(c < 150);
                ok(c > 100);
            }).always(start);
        });
    });

    asyncTest('Can count - promises', 1, function () {
        this.s.query(this.olderEmployees)
            .then(this.s.count)
            .then(is46)
            .always(start);
    });

    asyncTest('Can lift arguments into query', function () {
        this.s.count(this.olderEmployees)
            .done(is46)
            .always(start);
    });


})();

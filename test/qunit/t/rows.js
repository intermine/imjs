'use strict';

(function() {
    var get = intermine.funcutils.get,
        invoke = intermine.funcutils.invoke,
        flatMap = intermine.funcutils.flatMap,
        q = {select: ['age'], from: 'Employee', where: {age: {gt: 50}}},
        checkRows = function(rows) {
            equal(rows.length, 46);
            equal(flatMap(get(0))(rows), 2688);
        };

    module('Results Rows', TestCase);

    asyncTest('Can fetch rows - cb', 2, function() {
        this.s.query(q, function(query) {
            query.rows(_.compose(start, checkRows));
        });
    });

    asyncTest('Can fetch rows - promise', 2, function() {
        this.s.query(q).then(invoke('rows')).then(checkRows).always(start);
    });

    asyncTest('Can lift opts to query rows - promise', 2, function() {
        this.s.rows(q).then(checkRows).always(start);
    });
})();

(function() {
    var q = {select: ['age'], from: 'Employee', where: {age: {gt: 50}}},
        options = {
            setup: function() {
                var n = 0, total = 0;
                TestCase.setup.call(this);
                this.count = function(row) {
                    n++;
                    total += row[0];
                };
                this.checkTotal = function() {
                    equal(n, 46);
                    equal(total, 2688);
                    start();
                };
            }
        };

    module('Result Rows - Each', options);

    asyncTest('Can iterate over rows - cb', 2, function() {
        var self = this;
        this.s.query(q, function(query) {
            query.eachRow([self.count, self.fail, self.checkTotal]).fail(_.compose(start, self.fail));
        });
    });

})();

'use strict';

(function() {
    var get = intermine.funcutils.get,
        invoke = intermine.funcutils.invoke,
        fold = intermine.funcutils.fold,
        AND = intermine.funcutils.AND,
        curry = intermine.funcutils.curry,
        flip = intermine.funcutils.flip,
        is = function(x) { return function(y) { return x === y; }};

    module('Quick Search', TestCase);

    asyncTest('get all cbs', 2, function() {
        this.s.search(function(results, facets) {
            ok(results.length >= 100, 'Expected lots of results, got ' + results.length);
            equal(5, facets.Category.Bank, 'There should be 5 banks');
            start();
        });
    });

    asyncTest('get all: promises', 2, function() {
        this.s.search()
            .done(function(results)    { ok(results.length >= 100) })
            .done(function(__, facets) { equal(5, facets.Category.Bank) })
            .always(start);
    });

    asyncTest('get david', 1, function() {
        this.s.search('david')
            .done(function(results) { equal(2, results.length); })
            .always(start);
    });

    asyncTest('get managers', 2, function() {
        this.s.search({facets: {Category: 'Manager'}})
            .done(_.compose(curry(equal, 24), get('length')))
            .done(_.compose(ok, fold(true, AND), curry(flip(_.all), is('Manager')), invoke('map', get('type'))))
            .always(start);
    });

    asyncTest('limited', 1, function() {
        this.s.search({facets: {Category: 'Manager'}, size: 10})
            .done(_.compose(curry(equal, 10), get('length')))
            .always(start);
    });


})();

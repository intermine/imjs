'use strict';

(function() {
    var is4 = _.bind(equal, null, 4),
        get = intermine.funcutils.get;

    module('Lists', TestCase);

    asyncTest('All lists - cb', 1, function() {
        this.s.fetchLists(function(ls) {
            ok(ls.length > 0);
            start();
        });
    });

    asyncTest('All lists - promises', 1, function() {
        this.s.fetchLists().then(get('length')).then(ok).always(start);
    });

    asyncTest('fetches a list - promises', 1, function() {
        this.s.fetchList('My-Favourite-Employees')
            .then(get('size'))
            .then(is4)
            .always(start);
    });

    asyncTest('fetches a list - cb', 1, function() {
        this.s.fetchList('My-Favourite-Employees', function(l) {
            is4(l.size);
            start();
        });
    });

    asyncTest('Can find lists containing an item', 2, function() {
        this.s.fetchListsContaining({publicId: 'Brenda', type: 'Employee'}, function(ls) {
            ok(ls.length);
            ok(_.include(_.pluck(ls, 'name'), 'The great unknowns'));
            start();
        });
    });
})();

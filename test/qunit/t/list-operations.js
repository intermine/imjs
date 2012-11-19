'use strict';

(function() {
    var get    = intermine.funcutils.get,
        invoke = intermine.funcutils.invoke,
        flip   = intermine.funcutils.flip,
        tags   = ['js', 'qunit', 'testing'],
        namePrefix = 'temp-created-in-js-',
        clear  = function(service, name) { return function() {
            return new jQuery.Deferred(function() {
                service.fetchList(name).then(invoke('del')).always(this.resolve);
            });
        }},
        // Runs 4 tests for each operation.
        operationTest = function(service, args, method, size, employee) { return function() {
            return service[method](args)
                .done(_.compose(_.bind(equal, null, args.name), get('name')))
                .done(_.compose(_.bind(equal, null, size),      get('size')))
                .done(_.compose(ok,                             invoke('hasTag', 'js')))
                .then(invoke('contents'))
                .then(invoke('map', get('name')))
                .done(_.compose(ok, _.bind(flip(_.include), _, employee)));
        }},
        // Wrap the actual tests in code to delete the list before and after.
        operationTestCase = function(method, size, employee, args) {
            asyncTest(method, 4, function() {
                var clearList = clear(this.s, args.name),
                    onEnd = _.compose(start, clearList),
                    run = operationTest(this.s, args, method, size, employee);
                clearList().then(run).always(onEnd);
            });
        };

    module('List Operations', TestCase);

    operationTestCase('diff', 4, 'Brenda', {
        name: namePrefix + 'diff',
        tags: ['diff'].concat(tags),
        lists: ['The great unknowns', 'some favs-some unknowns-some umlauts']
    });

    operationTestCase('intersect', 2, 'David Brent', {
        name: namePrefix + 'intersect',
        tags: ['intersect'].concat(tags),
        lists: ['My-Favourite-Employees', 'some favs-some unknowns-some umlauts']
    });

    operationTestCase('merge', 6, 'David Brent', {
        tags: ['merge'].concat(tags),
        name: namePrefix + 'merge',
        lists: ['My-Favourite-Employees', 'Umlaut holders']
    });

})();

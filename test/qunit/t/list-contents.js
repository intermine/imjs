(function () {
    'use strict';

    var invoke = intermine.funcutils.invoke,
        curry  = intermine.funcutils.curry,
        get    = intermine.funcutils.get,
        flip   = intermine.funcutils.flip,
        name = 'My-Favourite-Employees';

    module('Get the contents of a list', window.TestCase);

    asyncTest('Get contents', 1, function () {
        this.s.fetchList(name)
            .then(invoke('contents'))
            .then(invoke('map', get('name')))
            .then(curry(flip(_.include), 'David Brent'))
            .then(curry(flip(ok), 'Includes David'))
            .always(start);
    });

    asyncTest('Get contents, despite joins', 1, function () {
        var args    = {name: 'temp-list-of-employees', tags: ['js', 'qunit', 'testing']},
            query   = {select: ['id'], from: 'Employee', where: {name: 'Employee*'}},
            list    = this.s.query(query).then(invoke('saveAsList', args)),
            cleanup = function () { list.done(invoke('del')); };

        list.then(invoke('contents'))
            .then(invoke('map', get('name')))
            .then(curry(flip(_.include), 'EmployeeB1'))
            .then(curry(flip(ok), 'Includes EmployeeB1'))
            .always(cleanup, start);
    });
})(); 

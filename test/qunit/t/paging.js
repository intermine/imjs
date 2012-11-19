'use strict';

(function() {
    var invoke  = intermine.funcutils.invoke,
        get     = intermine.funcutils.get,
        from0   = { select: ['*'], from: 'Employee', where: {age: {gt: 50}}, limit: 10, start: 0  },
        from20  = { select: ['*'], from: 'Employee', where: {age: {gt: 50}}, limit: 10, start: 20 },
        expected = [
            "Tatjana Berkel",
            "Jennifer Schirrmann",
            "Herr Fritsche",
            "Lars Lehnhoff",
            "Josef M\u00FCller",
            "Nyota N'ynagasongwa",
            "Herr Grahms",
            "Frank Montenbruck",
            "Andreas Hermann",
            "Jochen Sch\u00FCler"
        ],
        pageTest = function(query, method) { return function() {
            this.s.query(query)
                .then(invoke(method))
                .then(invoke('records'))
                .then(invoke('map', get('name')))
                .then(_.bind(deepEqual, null, expected))
                .always(start);
        }};

    module('Paging', TestCase);

    asyncTest('Can page forwards', 1, pageTest(from0, 'next'));

    asyncTest('Can page backwards', 1, pageTest(from20, 'previous'));

})();

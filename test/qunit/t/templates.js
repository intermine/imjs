(function() {
    var get = intermine.funcutils.get;

    module('get templates', TestCase);

    asyncTest('fetchTemplates(cb)', 1, function() {
        this.s.fetchTemplates(function(templates) {
            ok(templates.ManagerLookup);
            start();
        });
    });

    asyncTest('fetchTemplates().then()', 1, function() {
        this.s.fetchTemplates()
            .then(get('ManagerLookup'))
            .then(ok)
            .always(start);
    });

})();

'use strict';

(function() {
    var list = 'My-Favourite-Employees',
        widget = 'contractor_enrichment',
        get = intermine.funcutils.get,
        curry = intermine.funcutils.curry,
        invoke = intermine.funcutils.invoke;

    module('Enrichment', TestCase);

    asyncTest('Gets a list of enrichment widgets', 1, function() {
        this.s.fetchWidgets().then(get('length')).done(ok).always(start);
    });

    asyncTest('Gets a specific widget', 1, function() {
        this.s.fetchWidgetMap().then(get(widget)).done(ok).always(start);
    });

    asyncTest('Service#enrichment', 3, function() {
        this.s.enrichment({list: list, widget: widget, maxp: 1})
            .done(ok)
            .done(_.compose(_.bind(equal, null, 1), get('length')))
            .done(_.compose(_.bind(equal, null, 'Vikram'), get('identifier'), get(0)))
            .always(start);
    });

    asyncTest('List#enrichment', 3, function() {
        this.s.fetchList('My-Favourite-Employees')
            .then(invoke('enrichment', {widget: widget, maxp: 1}))
            .done(ok)
            .done(_.compose(curry(equal, 1), get('length')))
            .done(_.compose(curry(equal, 'Vikram'), get('identifier'), get(0)))
            .always(start);
    });

})();

'use strict';

(function() {
    var invoke = intermine.funcutils.invoke,
        set    = intermine.funcutils.set,
        args   = {name: 'temp-olders', tags: ['js', 'qunit', 'testing']},
        clear  = function(service, name) { return function() {
            return new jQuery.Deferred(function() {
                service.fetchList(name).then(invoke('del')).always(this.resolve);
            });
        }};
        
    module('Append to list', TestCase);

    asyncTest('Can append to a list from a query', 3, function() {
        var self = this, count = this.s.count, query = this.s.query,
            clearList = clear(this.s, args.name),
            run = function() {
                return $.when(
                      count(set({select: ['id']})(self.allEmployees)),
                      query(self.youngerEmployees),
                      query(self.olderEmployees).then(invoke('saveAsList', args))
                    ).then(function(total, yq, list) {
                    var startSize = list.size;
                    return yq.appendToList(list)
                      .done(function(now) { ok(startSize < now.size,   'List is bigger');     })
                      .done(function(now) { equal(list.size, now.size, 'Lists are in synch'); })
                      .done(function(now) { equal(now.size, total,     'List now has all');   });
                });
            };

        clearList().then(run).always(clearList, start);
    });

})();

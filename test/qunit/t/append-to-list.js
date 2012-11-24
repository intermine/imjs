(function () {
    'use strict';

    var invoke = intermine.funcutils.invoke
      , set    = intermine.funcutils.set
      , args   = {name: 'temp-olders', tags: ['js', 'qunit', 'testing']}
    
    function clear(service, name) {
        return function () {
            var action = function () {service.fetchList(name).then(invoke('del')).always(this.resolve)}
            return jQuery.Deferred(action);
        }
    }
        
    module('Append to list', window.TestCase);

    asyncTest('Can append to a list from a query', 3, function () {
        var self = this
          , count = this.s.count
          , query = this.s.query
          , clearList = clear(this.s, args.name)

        function run() {
            return $.when(
                    count(set({select: ['id']})(self.allEmployees)),
                    query(self.youngerEmployees),
                    query(self.olderEmployees).then(invoke('saveAsList', args))
                ).then(function (total, yq, list) {
                var startSize = list.size;
                return yq.appendToList(list)
                    .done(function (now) { ok(startSize < now.size,   'List is bigger');     })
                    .done(function (now) { equal(list.size, now.size, 'Lists are in synch'); })
                    .done(function (now) { equal(now.size, total,     'List now has all');   });
            });
        }

        clearList().then(run).always(clearList, start);
    });

})();

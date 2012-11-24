(function () {
    'use strict';

    var invoke  = intermine.funcutils.invoke
      , flip    = intermine.funcutils.flip
      , get     = intermine.funcutils.get
      , curry   = intermine.funcutils.curry
      , content = "Anne, Brenda, Carol, David*"
      , names   = ['Anne', 'Brenda', 'Charles Miner', 'David*']
      , description = 'A temporary list uploaded with imjs in the qunit tests'
      , tags = ['js', 'temp', 'qunit']
      , args = { name: "temp-uploaded-list", type: "Employee", tags: tags, description: description }

    function clear(service, name) {
        return function () {
            return new jQuery.Deferred(function () {
                service.fetchList(name).then(invoke('del')).always(this.resolve);
            }).promise();
        }
    }

    module('List Upload', window.TestCase);

    asyncTest('Can upload a list - string content', 4, function () {
        var firstly = clear(this.s, args.name),
            cleanup = _.compose(start, firstly),
            hasRight = function (prop, value) {
                return _.compose(curry(flip(equal), 'Has right ' + prop, value), get(prop));
            },
            hasTag  = _.compose(curry(flip(ok), 'Has tag'), invoke('hasTag', 'js')),
            upload  = curry(this.s.createList, args, content);

        firstly()
            .then(upload)
            .done(
                hasRight('size', 3),
                hasRight('name', args.name),
                hasRight('description', args.description),
                hasTag)
            .always(cleanup);
    });

    asyncTest('Can upload a list - list content', 2, function () {
        var firstly = clear(this.s, args.name),
            cleanup = _.compose(start, firstly),
            has3Members = _.compose(curry(flip(equal), 'Has correct size', 3), get('size')),
            hasCharles  = invoke('contents', _.compose(curry(flip(ok), 'Includes Charles'), curry(flip(_.include), 'Charles Miner'), invoke('map', get('name')))),
            upload  = curry(this.s.createList, args, names);

        firstly().then(upload).done(has3Members).then(hasCharles).always(cleanup);
    });
})();

(function() {
    var id     = intermine.funcutils.id,
        invoke = intermine.funcutils.invoke,
        get    = intermine.funcutils.get,
        NOT    = intermine.funcutils.NOT,
        pathsAndTypes = [
            ['Employee.age', 'int'],
            ['Department.employees.name', 'String'],
            ['Department.employees.seniority', 'Integer',  {'Department.employees': 'Manager'}],
            ['Department.employees.company.vatNumber', 'int', {'Department.employees': 'CEO'}]
        ],
        pathsAndParentTypes = [
            ['Company.name', 'Company'],
            ['Department.employees.name', 'Employee'],
            ['Department.employees.name', 'Manager', {'Department.employees': 'Manager'}]
        ];

    module('Path Info', TestCase);

    var isType = function(fn_0, fn_1, str, type, subclasses) {
        var fn = _.compose(fn_1, invoke('getType'), fn_0);
        return function() {
            this.s.fetchModel(function(m) {
                var path = m.makePath(str, subclasses);
                equal(fn(path), type);
                start();
            });
        };
    };

    var pathIs   = _.bind(isType, null, id, id);
    var parentIs = _.bind(isType, null, invoke('getParent'), get('name'));

    _.each(pathsAndTypes, function(args, i) {
        asyncTest('PathInfo#getType() ' + i, 1, pathIs.apply(null, args));
    });

    _.each(pathsAndParentTypes, function(args, i) {
        asyncTest('PathInfo#getParent().getType() ' + i, 1, parentIs.apply(null, args));
    });

    asyncTest('To String', 3, function() {
        var path = 'Company.departments.employees.address.address',
            checker = function(m) { return function (f) {
                equal(path, f(m.getPathInfo(path)));
            }};
        this.s.fetchModel().then(checker).then(function(check) {
            check(invoke('toPathString'));
            check(invoke('toString'));
            check(function(x) { return '' + x; });
            start();
        });
    });

    asyncTest('PathInfo#containsCollection', 16, function() {
        var 
            attr = 'Company.departments.employees.address.address',
            ref  = 'Company.departments.employees.address',
            coll = 'Company.departments.employees',
            root = 'Company',
            checker = function(m) { return function(path, predicate, f) {
                ok(f(m.getPathInfo(path)[predicate]()), path + ' contains collection');
            }};

        this.s.fetchModel().then(checker).then(function(check) {

            check(attr, 'isAttribute', id);
            check(attr, 'isReference', NOT);
            check(attr, 'isCollection', NOT);
            check(attr, 'isClass', NOT);

            check(ref, 'isAttribute', NOT);
            check(ref, 'isReference', id);
            check(ref, 'isCollection', NOT);
            check(ref, 'isClass', id);

            check(coll, 'isAttribute', NOT);
            check(coll, 'isReference', id);
            check(coll, 'isCollection', id);
            check(coll, 'isClass', id);

            check(root, 'isAttribute', NOT);
            check(root, 'isReference', NOT);
            check(root, 'isCollection', NOT);
            check(root, 'isClass', id);

        }).always(start);
    });

})();

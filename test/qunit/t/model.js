(function () {
    'use strict';

    module('Metadata management', window.TestCase);

    var typesAndCommonTypes
      , name        = 'testmodel'
      , utils       = intermine.funcutils
      , invoke      = utils.invoke
      , nameIsRight = _.bind(utils.flip(equal), null, 'Name is ' + name, name)
      , things      = [ "Thing", "Employable", "Contractor", "Employee", "Manager", "CEO", "Address"]
      , employees   = [ "Employee", "Manager", "CEO"]

    typesAndCommonTypes = [
        [['CEO', 'Manager'], 'Manager']
        , [['Manager', 'CEO'], 'Manager']
        , [['Company', 'Employee'], 'HasAddress']
        , [['CEO', 'Department'], undefined]
        , [['CEO', 'Address'], 'Thing']
        , [['Employee', 'Contractor', 'Manager'], 'Employable']
        , [things, 'Thing']
    ];

    asyncTest('Model#name', 1, function () {
        this.s.fetchModel(function (m) {
            nameIsRight(m.name);
            start();
        });
    });

    asyncTest('Model#name - promise', 1, function () {
        this.s.fetchModel()
            .then(utils.get('name'))
            .then(nameIsRight)
            .always(start);
    });

    asyncTest('Model#classes', 2, function () {
        this.s.fetchModel(function (m) {
            ok(m.classes, "Has classes");
            ok(m.classes.Employee, "Has classes[Employee]");
            start();
        });
    });

    var theseAreThat = function (these, that) {
        return function (m) {
            equal(that, m.findCommonType(these));
        };
    };

    asyncTest('Model#findCommonType',
            typesAndCommonTypes.length,
            function () {
        var self = this,
            promises = _.map(typesAndCommonTypes, function (args) {
            return self.s.fetchModel().then(theseAreThat.apply(null, args));
        });
        $.when(promises).always(start);
    });

    asyncTest('Model#getSubclassesOf("Thing")', 1, function () {
        this.s.fetchModel()
            .then(invoke('getSubclassesOf', 'Thing'))
            .then(_.bind(deepEqual, null, things))
            .always(start);
    });

    asyncTest('Model#getSubclassesOf("Employee")', 1, function () {
        this.s.fetchModel()
            .then(invoke('getSubclassesOf', 'Employee'))
            .then(_.bind(deepEqual, null, employees))
            .always(start);
    });

    asyncTest('Model#makePath("Employee.age")', 1, function () {
        this.s.fetchModel()
            .then(invoke('makePath', 'Employee.age'))
            .then(invoke('getType'))
            .then(_.bind(equal, null, 'int'))
            .always(start);
    });

})();

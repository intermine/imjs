(function() {
    var get      = intermine.funcutils.get,
        expected = [
            "Employee.name",
            "Employee.department.name",
            "Employee.department.manager.name",
            "Employee.department.company.name",
            "Employee.fullTime",
            "Employee.address.address"
        ];

    module('Summary Fields', TestCase);

    asyncTest('Service#fetchSummaryFields()', 1, function() {
        this.s.fetchSummaryFields().then(this.success, this.fail);
    });

    asyncTest('Service#fetchSummaryFields(cb)', 1, function() {
        this.s.fetchSummaryFields(function(sfs) {
            deepEqual(expected, sfs.Employee);
            start();
        });
    });

    asyncTest('Service#fetchSummaryFields().then(cb)', 1, function() {
        this.s.fetchSummaryFields()
            .then(get('Employee'))
            .then(_.bind(deepEqual, null, expected))
            .always(start);
    });
});


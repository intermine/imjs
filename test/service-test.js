module("Service Tests", {
    setup: function() {
        this.s = new intermine.Service({root: "localhost/intermine-test", token: "test-user-token"});
    }
});

test('root property', function() {
    expect(2);
    equals(this.s.root, "http://localhost/intermine-test/service/", "The root parameter is set correctly");
    equals(new intermine.Service({root: "http://www.flymine.org/query/service/"}).root, 
        "http://www.flymine.org/query/service/", "Appropriately complete URLs are not altered");
});

asyncTest('fetching', function() {
    expect(4);
    this.s.fetchVersion(function(v) {
        console.log(v);
        ok(v > 0, "Can fetch version");
        start();
    });
    this.s.fetchModel(function(m) {
        console.log(m);
        ok(_.size(m.classes) > 0, "Can fetch model");
        start();
    });
    this.s.fetchTemplates(function(ts) { 
        ok(_.size(ts) > 0, "Can fetch templates");
        start();
    });
    this.s.fetchLists(function(ls) { 
        console.log(ls);
        ok(_.size(ls) > 0, "Can fetch lists");
        start();
    });
});

asyncTest('xml expansion', 1, function() {
    var older_emps = {select: ["*"], from: "Employee", where: {age: {gt: 50}}};
    this.s.query(older_emps, function(q) {
        var expected =  "<query model=\"testmodel\" view=\"Employee.name Employee.department.name Employee.department.manager.name Employee.department.company.name Employee.fullTime Employee.address.address\"><constraint path=\"Employee.age\" op=\"&gt;\" value=\"50\"/></query>";
        equals(q.toXML(), expected, "XML is correct"); 
        start();
    });
});

asyncTest('counting', 1, function() {
    var older_emps = {select: ["*"], from: "Employee", where: {age: {gt: 50}}};
    var t = _.compose(start, _(equals).bind(this, 46));
    this.s.query(older_emps, function(q) {
        q.count(t);
    });
});

asyncTest('rows', 1, function() {
    var older_emps = {select: ["*"], from: "Employee", where: {age: {gt: 50}}, limit: 10};
    this.s.query(older_emps, function(q) {
        q.rows(function(rs) {
            _(rs).each(function(r) {console.log(r)});
            ok(true);
            start();
        });
    });
});

asyncTest('results', 1, function() {
    var older_emps = {select: ["*"], from: "Employee", where: {age: {gt: 50}}, limit: 10};
    this.s.query(older_emps, function(q) {
        q.records(function(rs) {
            var names = _(rs).pluck("name")
            var expected =  [
                "EmployeeB3",
                "Jennifer Taylor-Clarke",
                "Keith Bishop",
                "Trudy",
                "Rachel",
                "Carol",
                "Brenda",
                "Nathan",
                "Gareth Keenan",
                "Malcolm"
            ];
            same(names, expected);
            start();
        });
    });
});

asyncTest('paging', 1, function() {
    var older_emps = {select: ["*"], from: "Employee", where: {age: {gt: 50}}, limit: 10};
    this.s.query(older_emps, function(q) {
        q.next().records(function(rs) {
            var names = _(rs).pluck("name")
            var expected =  [
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
            ];
            same(names, expected);
            start();
        });
    });
});


asyncTest('findById', 4, function() {
    var davidQ = {select: ["id"], from: "Employee", where: {name: "David Brent"}};
    var s = this.s;
    s.query(davidQ, function(q) {
        q.rows(function(rs) {
            var d_id = rs[0][0];
            s.findById("Employee", d_id, function(david) {
                equals("David Brent", david.name);
                equals("Sales", david.department.name);
                equals(41, david.age);
                equals(false, david.fullTime);
                start();
            });
        });
    });
});




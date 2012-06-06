module("Service Tests", {
    setup: function() {
        this.s = new intermine.Service({root: "squirrel/intermine-test", token: "test-user-token"});
    }
});

test('root property', function() {
    expect(2);
    equals(this.s.root, "http://squirrel/intermine-test/service/", "The root parameter is set correctly");
    equals(new intermine.Service({root: "http://www.flymine.org/query/service/"}).root, 
        "http://www.flymine.org/query/service/", "Appropriately complete URLs are not altered");
});

asyncTest('version', 1, function() {
    this.s.fetchVersion(function(v) {
        console.log(v);
        ok(v > 0, "Can fetch version");
        start();
    });
});

asyncTest('model', 1, function() {
    this.s.fetchModel(function(m) {
        console.log(m);
        ok(_.size(m.classes) > 0, "Can fetch model");
        start();
    });
});

asyncTest('get templates', 1, function() {
    this.s.fetchTemplates(function(ts) { 
        ok(_.size(ts) > 0, "Can fetch templates");
        start();
    });
});

asyncTest('get lists', 1, function() {
    this.s.fetchLists(function(ls) { 
        console.log(ls);
        ok(_.size(ls) > 0, "Can fetch lists");
        start();
    });
});

asyncTest("summary fields", 1, function() {
    this.s.fetchSummaryFields(function(sfs) {
        var expected = [
          "Employee.name",
          "Employee.department.name",
          "Employee.department.manager.name",
          "Employee.department.company.name",
          "Employee.fullTime",
          "Employee.address.address"
        ];
        same(sfs.Employee, expected, "Has the right summary fields");
        start();
    });
});


asyncTest('xml expansion', 1, function() {
    var older_emps = {select: ["*"], from: "Employee", where: {age: {gt: 50}}};
    this.s.query(older_emps, function(q) {
        var expected =  "<query model=\"testmodel\" view=\"Employee.name Employee.department.name Employee.department.manager.name Employee.department.company.name Employee.fullTime Employee.address.address\" ><constraint path=\"Employee.age\" op=\"&gt;\" value=\"50\" /></query>";
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
    var older_emps = {select: ["name"], from: "Employee", where: {age: {gt: 50}}, limit: 10};
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
    var older_emps = {select: ["name"], from: "Employee", where: {age: {gt: 50}}, limit: 10};
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
        }).fail(fail).always(start);
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

var succeed = function() {ok(true)};
var fail = function(err, msg) {
    console.log("FAILURE", arguments); 
    ok(false, err + " " + msg); 
    return Array.prototype.slice.call(arguments);
};

asyncTest('union', 3, function() {
    var ls = ["My-Favourite-Employees", "Umlaut holders"];
    var new_name = "created_in_js-union";
    var tags = ["js"];
    var then = new Date();
    this.s.merge({name: new_name, lists: ls, tags: tags}, function(l) {
        ok(l.size === 6, "It has the right size");
        ok(l.hasTag("js"), "Is correctly tagged");
        l.del().then(succeed, fail).always(start);
    });
});
             
asyncTest('intersect', 3, function() {
    var ls = [
        "My-Favourite-Employees", 
        "some favs-some unknowns-some umlauts"
    ];
    var new_name = "created_in_js-intersect";
    var tags = ["js"];
    this.s.intersect({name: new_name, lists: ls, tags: tags}, function(l) {
        ok(l.size === 2, "It has the right size");
        ok(l.hasTag("js"), "Is correctly tagged");
        l.del().then(succeed, fail).always(start);
    });
});

asyncTest('diff', 4, function() {
    var ls = [
        "The great unknowns",
        "some favs-some unknowns-some umlauts"
    ];
    var new_name = "created_in_js-diff";
    var tags = ["js"];
    this.s.diff({name: new_name, lists: ls, tags: tags}, function(l) {
        ok(l.size === 4, "It has the right size");
        ok(l.hasTag("js"), "Is correctly tagged");
        l.contents(function(xs) {
            ok(_(xs).any(function(x) {return x.name === "Brenda"}), 
                "contains Brenda");
            l.del().then(succeed, fail).always(start);
        });
    });
});

asyncTest("summarise", 1, function() {
    var older_emps = {select: ["*"], from: "Employee", where: {age: {gt: 50}}};
    this.s.query(older_emps, function(q) {
        q.summarise("department.company.name", function(items) {
            console.log(items);
            equals(_(items).size(), 6);
            start();
        });
    });
});

asyncTest("who-am-i", 1, function() {
    this.s.whoami(function(u) {
        equals(u.username, "intermine-test-user", "Can retrieve the user name");
    }).fail(fail).always(start);
});

asyncTest("query to list", 4, function() {
    var older_emps = {select: ["*"], from: "Employee", where: {age: {gt: 50}}};
    this.s.query(older_emps, function(q) {
        q.saveAsList({name: "list-from-js-query", tags: ["foo", "bar", "js"]}, function(l) {
            equals(l.size, 46, "It has the right size");
            ok(l.hasTag("js"), "Is correctly tagged: " + l.tags);
            l.contents(function(xs) {
                console.log("Contents", xs);
                ok(_(xs).any(function(x) {return x.name === "Carol"}), 
                    "contains Carol");
                l.del().then(succeed, fail).always(start);
            });
        });
    });
});

asyncTest("append to list from query", 4, function() {
    var older_emps = {select: ["*"], from: "Employee", where: {age: {gt: 50}}};
    var younger_emps = {select: ["*"], from: "Employee", where: {age: {le: 50}}};
    var all_emps = {select: ["id"], from: "Employee"};
    var self = this;
    var tripleFail = _.compose(fail, fail, fail, fail);
    var proceed = _.compose(tripleFail, start);
    self.s.query(all_emps, function(all) {
        all.count(function(count) {
            self.s.query(older_emps, function(olders_q) {
                olders_q.saveAsList({name: "temp-olders", tags: ["from-js"]}, function(olders_l) {
                    var startSize = olders_l.size;
                    self.s.query(younger_emps, function(younger_q) {
                        younger_q.appendToList(olders_l, function(updated_olders) {
                            ok(startSize < count, "Started out with less than all (all being " + count + ")");
                            equals(count, updated_olders.size, "Now we have them all");
                            equals(updated_olders.size, olders_l.size, "The input list was updated");
                            updated_olders.del().then(succeed, fail).always(start);
                        }).fail(tripleFail);
                    }).fail(proceed);
                }).fail(proceed);
            }).fail(proceed);
        }).fail(proceed);
    }).fail(proceed);
});

                            
asyncTest("quick-search", 4, function() {
    var self = this;
    self.s.search(function(rs, fs) {
        ok(rs.length >= 100, "Has a suitably large number of results");
        //console.log(rs, fs);
        equals(fs.Category.Bank, 5, "Has a category facet");
        self.s.search("david", function(rs) {
            equals(rs.length, 2, "Has the right number of results");
        }).fail(fail).always(function() {
            self.s.search({facets: {Category: "Manager"}, size: 10}, function(rs) {
                equals(rs.length, 10, "Can limit results, and use options objects");
            }).fail(fail).always(start);
        });
    });
});

asyncTest("lists with object", 1, function() {
    this.s.fetchListsContaining({publicId: "Brenda", type: "Employee"}, function(ls) {
        ok(ls.length > 1, "Has a suitable number of lists");
    }).fail(fail).always(start);
});

asyncTest("path info parsing", 4, function() {
    this.s.fetchModel( function( m ) {
        var path, pi;
        path = "Employee.age";
        pi   = m.getPathInfo(path);
        equals(pi.getType(), "int");
        path = "Department.employees.name";
        pi   = m.getPathInfo(path);
        equals(pi.getType(), "String");
        path = "Department.employees.seniority";
        pi   = m.getPathInfo(path, {"Department.employees": "Manager"});
        equals(pi.getType(), "Integer");
        path = "Department.employees.company.vatNumber";
        pi   = m.getPathInfo(path, {"Department.employees": "CEO"});
        equals(pi.getType(), "int");
    }).fail(fail).always(start);
});





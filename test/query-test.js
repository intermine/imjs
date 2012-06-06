module("Query Tests");

test('new Query()', function() {
    ok(new intermine.Query(), "Can construct a query");
});
test('root property', function() {
    equals(new intermine.Query({root: "Gene"}).root, "Gene", "The root parameter is set correctly");
    equals(new intermine.Query({from: "Gene"}).root, "Gene", "The root parameter is set correctly");
});
test('views in constructor', function() {
    same(
        new intermine.Query({root: "Gene", views: ["Gene.symbol", "Gene.length"]}).views,
        ["Gene.symbol", "Gene.length"],
        "The views are set correctly"
    );
    same(
        new intermine.Query({root: "Gene", select: ["Gene.symbol", "Gene.length"]}).views,
        ["Gene.symbol", "Gene.length"],
        "The views are set correctly"
    );
    same(
        new intermine.Query({root: "Gene", select: ["symbol", "length"]}).views,
        ["Gene.symbol", "Gene.length"],
        "The views are set correctly"
    );

    same(
        new intermine.Query({select: ["Gene.symbol", "Gene.length"]}).views,
        ["Gene.symbol", "Gene.length"],
        "The views are set correctly"
    );
});
test('constraints in constructor', function() {
    same(
        new intermine.Query({root: "Gene", constraints: [
            {path: "Gene.symbol", op: "=", value: "zen"},
            {path: "Gene.length", op: ">", value: 1000}
        ]}).constraints,
        [
            {path: "Gene.symbol", op: "=", value: "zen"},
            {path: "Gene.length", op: ">", value: 1000}
        ],
        "The constraints are set correctly"
    );
    same(
        new intermine.Query({root: "Gene", constraints: [
            {path: "symbol", op: "=", value: "zen"},
            {path: "length", op: ">", value: 1000}
        ]}).constraints,
        [
            {path: "Gene.symbol", op: "=", value: "zen"},
            {path: "Gene.length", op: ">", value: 1000}
        ],
        "The constraints are set correctly"
    );
    same(
        new intermine.Query({root: "Employee", constraints: [
            ["department.manager", "CEO"],
            ["name", "=", "David*"],
            ["end", "is not null"],
            ["age", ">", 50]
        ]}).constraints,
        [
            {path: "Employee.department.manager", type: "CEO"},
            {path: "Employee.name", op: "=", value: "David*"},
            {path: "Employee.end", op: "IS NOT NULL"},
            {path: "Employee.age", op: ">", value: 50}
        ],
        "The constraints are set correctly"
    );
    same(
        new intermine.Query({
            root: "Employee", 
            where: {
                "department.manager": {isa: "CEO"},
                "name": "David*",
                "end": "is not null",
                "age": {gt: 50},
                "department.name": ["Sales", "Accounting"]
            }
        }).constraints,
        [
            {path: "Employee.department.manager", type: "CEO"},
            {path: "Employee.name", op: "=", value: "David*"},
            {path: "Employee.end", op: "IS NOT NULL"},
            {path: "Employee.age", op: ">", value: 50},
            {path: "Employee.department.name", op: "ONE OF", values: ["Sales", "Accounting"]}
        ],
        "The constraints are set correctly"
    );
    same(
        new intermine.Query({root: "Employee", where: [
            ["department.manager", "CEO"],
            ["name", "=", "David*"],
            ["end", "is not null"],
            ["age", ">", 50],
            ["department.name", "one of", ["Sales", "Accounting"]]
        ]}).constraints,
        [
            {path: "Employee.department.manager", type: "CEO"},
            {path: "Employee.name", op: "=", value: "David*"},
            {path: "Employee.end", op: "IS NOT NULL"},
            {path: "Employee.age", op: ">", value: 50},
            {path: "Employee.department.name", op: "ONE OF", values: ["Sales", "Accounting"]}
        ],
        "The constraints are set correctly"
    );
});
test("joins in constructor", function() {
    var q;
    q = new intermine.Query();
    console.log("JOINS", q.joins);
    same(q.joins, {}, "No joins by default");
    same(
        new intermine.Query({root: "Employee", joins: [
            {path: "department", style: "OUTER"},
            {path: "department.company", style: "OUTER"}
        ]}).joins,
        {
            "Employee.department": "OUTER",
            "Employee.department.company": "OUTER"
        },
        "The joins are set properly"
    );
    same(
        new intermine.Query({root: "Employee", joins: ["department", "department.company"]}).joins,
        {
            "Employee.department": "OUTER",
            "Employee.department.company": "OUTER"
        },
        "The joins are set properly"
    );
});
test('logic in constructor', function() {
    equals(new intermine.Query().constraintLogic, "", "Empty logic by default");
    equals(
        new intermine.Query({
            root: "Employee", 
            constraints: [
                ["department.manager", "CEO"],
                ["name", "=", "David*"],
                ["end", "is not null"],
                ["age", ">", 50]
            ], 
            constraintLogic: "A or B and C"
        }).constraintLogic,
        "A or B and C",
        "Sets constraint logic in constructor"
    );
});
test('sort order in constructor', function() {
    same(new intermine.Query().sortOrder, [], "Empty sort-order by default");
    same(
        new intermine.Query({
            root: "Employee", 
            views: ["name", "age", "fullTime"],
            sortOrder: [
                {path: "age", direction: "DESC"},
                {path: "name", direction: "ASC"}
            ]
        }).sortOrder,
        [
            {path: "Employee.age", direction: "DESC"},
            {path: "Employee.name", direction: "ASC"}
        ],
        "Can set sort order from list of objects"
    );
    same(
        new intermine.Query({
            root: "Employee", 
            views: ["name", "age", "fullTime"],
            sortOrder: [
                {path: "age", direction: "desc"},
                {path: "name", direction: "asc"}
            ]
        }).sortOrder,
        [
            {path: "Employee.age", direction: "DESC"},
            {path: "Employee.name", direction: "ASC"}
        ],
        "Can set sort order from list of objects, uppercasing the directions"
    );
    same(
        new intermine.Query({
            root: "Employee", 
            views: ["name", "age", "fullTime"],
            sortOrder: ["age", "name"]
        }).sortOrder,
        [
            {path: "Employee.age", direction: "ASC"},
            {path: "Employee.name", direction: "ASC"}
        ],
        "Can set sort order from list of strings"
    );
    same(
        new intermine.Query({
            root: "Employee", 
            views: ["name", "age", "fullTime"],
            sortOrder: [{age: "DESC"}, {name: "ASC"}]
        }).sortOrder,
        [
            {path: "Employee.age", direction: "DESC"},
            {path: "Employee.name", direction: "ASC"}
        ],
        "Can set sort order from path:direction pairs"
    );
});

test('service reference', function() {
    equals(
        new intermine.Query({}, "SERVICE").service,
        "SERVICE",
        "Service property is set when passed"
    );
});
test('toXML()', function() {
    equals(
        new intermine.Query({
            select: ["name", "age", "department.name"],
            from: "Employee", 
            joins: ["department.manager", "department.company"],
            where: {
                "department.manager": {"isa": "CEO"},
                "name": "David*",
                "end": "is not null",
                "age": {"gt": 50},
                "department.name": ["Sales", "Accounting"],
                "department": {"in": "GoodDepartments"}
            },
            model: {name: "testmodel"}
        }).toXML(),
        '<query model="testmodel" view="Employee.name Employee.age Employee.department.name" >'
         + '<join path="Employee.department.manager" style="OUTER"/>'
         + '<join path="Employee.department.company" style="OUTER"/>'
         + '<constraint path="Employee.department.manager" type="CEO" />'
         + '<constraint path="Employee.name" op="=" value="David*" />'
         + '<constraint path="Employee.end" op="IS NOT NULL" />'
         + '<constraint path="Employee.age" op="&gt;" value="50" />'
         + '<constraint path="Employee.department.name" op="ONE OF">'
         +   '<value>Sales</value>'
         +   '<value>Accounting</value>'
         + '</constraint>'
         + '<constraint path="Employee.department" op="IN" value="GoodDepartments" />'
         + '</query>',
        "Can serialise to XML"
    );
    equals(
        new intermine.Query({
            select: ["name", "age", "department.name"],
            from: "Employee", 
            joins: ["department.manager", "department.company"],
            where: {
                "department.manager": {isa: "CEO"},
                "name": "David*",
                "end": "is not null",
                "age": {gt: 50},
                "department.name": ["Sales", "Accounting"]
            },
            orderBy: ["age", "name"],
            model: {name: "testmodel"}
        }).toXML(),
        '<query model="testmodel" view="Employee.name Employee.age Employee.department.name" '
         + 'sortOrder="Employee.age ASC Employee.name ASC" >'
         + '<join path="Employee.department.manager" style="OUTER"/>'
         + '<join path="Employee.department.company" style="OUTER"/>'
         + '<constraint path="Employee.department.manager" type="CEO" />'
         + '<constraint path="Employee.name" op="=" value="David*" />'
         + '<constraint path="Employee.end" op="IS NOT NULL" />'
         + '<constraint path="Employee.age" op="&gt;" value="50" />'
         + '<constraint path="Employee.department.name" op="ONE OF">'
         +   '<value>Sales</value>'
         +   '<value>Accounting</value>'
         + '</constraint>'
         + '</query>',
        "Can serialise to XML with sort order"
    );
    equals(
        new intermine.Query({
            select: ["name", "age", "department.name"],
            from: "Employee", 
            where: {
                "name": {contains: "<"},
                "department.name": ["R & D", ">"]
            },
            model: {name: "testmodel"}
        }).toXML(),
        '<query model="testmodel" view="Employee.name Employee.age Employee.department.name" >'
         + '<constraint path="Employee.name" op="CONTAINS" value="&lt;" />'
         + '<constraint path="Employee.department.name" op="ONE OF">'
         +   '<value>R &amp; D</value>'
         +   '<value>&gt;</value>'
         + '</constraint>'
         + '</query>',
        "Can serialise to XML, escaping values that need it."
    );
});

var succeed = function() {ok(true)};
var fail = function(err, msg) {
    console.log("FAILURE", arguments); 
    ok(false, err + " " + msg); 
    return Array.prototype.slice.call(arguments);
};

asyncTest('clone does not grab all events', 1, function() {
    var q = new intermine.Query({}, "SERVICE");
    q.on("test:event", _.compose(start, succeed));
    var c = q.clone();
    c.on("test:event", _.compose(start, fail));
    q.trigger("test:event");
});


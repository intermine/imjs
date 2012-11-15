{asyncTest} = require './lib/service-setup'
$ = require 'underscore.deferred'

trad =
    view: ["Employee.name", "Employee.age", "Employee.department.name"]
    constraints: [
        {path: "Employee.department.name", op: '=', value: "Sales*"},
        {path: "Employee.age", op: ">", value: "50"}
    ]

sqlish =
    from: "Employee"
    select: ["name", "age", "department.name"]
    where:
        'department.name': 'Sales*'
        'age': {gt: 50}

exports['different arg styles are synonymous'] = asyncTest 1, (bt, A) ->
    $.when(@service.query(trad), @service.query(sqlish))
     .then @testCB (qa, qb) -> A.eql qa.toXML(), qb.toXML()
    


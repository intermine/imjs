{Service} = require '../../../bin/index'

args =
    root: 'localhost/intermine-test'
    token: 'test-user-token'

module.exports = ->
    service = new Service args

    allEmployees =
        select: ['*']
        from: 'Employee'

    olderEmployees =
        select: ['*']
        from: 'Employee'
        where:
            age:
                gt: 50

    youngerEmployees =
        select: ['*']
        from: 'Employee'
        where:
            age:
                le: 50

    {service, allEmployees, olderEmployees, youngerEmployees}

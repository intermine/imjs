{Service} = require '../../../lib/service'
{testCase, asyncTestCase} = require './util'

exports.setup = setup = () ->
    s = new Service root: 'squirrel/intermine-test', token: 'test-user-token'
    {service: s}

exports.test = testCase setup
exports.asyncTest = asyncTestCase setup
exports.older_emps = select: ['*'], from: 'Employee', where: {age: {gt: 50}}




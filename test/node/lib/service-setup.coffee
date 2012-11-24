{Service} = require '../../../bin/index'
{testCase, asyncTestCase} = require './util'
{invoke}  = require '../../../src/util'
{Deferred} = require 'underscore.deferred'

exports.setup = setup = () ->
    s = new Service root: 'squirrel/intermine-test', token: 'test-user-token'
    {service: s}

exports.test = testCase setup
exports.asyncTest = asyncTestCase setup
exports.older_emps = select: ['*'], from: 'Employee', where: {age: {gt: 50}}

exports.clearTheWay = (service, name) -> Deferred ->
    service.fetchList(name).then(invoke 'del').always(@resolve)


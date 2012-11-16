{Deferred} = require 'underscore.deferred'
{Model} = require '../../src/model'

{asyncTestCase} = require './lib/util'
{TESTMODEL} = require './data/model'

things = ["Thing","Employable","Contractor","Employee","Manager","CEO","Address"]

async = asyncTestCase ->
    gotModel = Deferred ->
        if TESTMODEL?.model
            try
                @resolve new Model TESTMODEL.model
            catch e
                @reject e
        else
            @reject new Error("Incorrect json structure. #{ TESTMODEL }")
    theseAreThis = (m, types, common) ->
        @runTest => @assert.eql common, m.findCommonType(types), "#{ types } are all #{ common }"
    {gotModel, theseAreThis}

exports['#findCommonType'] = async 7, (beforeExit, assert) ->
    @gotModel.fail(@failN 7).done (m) =>
        @theseAreThis m, ['CEO', 'Manager'], 'Manager'
        @theseAreThis m, ['Manager', 'CEO'], 'Manager'
        @theseAreThis m, ['Company', 'Employee'], 'HasAddress'
        @theseAreThis m, ['CEO', 'Department'], undefined
        @theseAreThis m, ['CEO', 'Address'], 'Thing'
        @theseAreThis m, ['Employee', 'Contractor', 'Manager'], 'Employable'
        @theseAreThis m, things, 'Thing'

exports['#getSubclassesOf'] = async 3, ->
    @gotModel.fail(@failN 3).done (m) =>
        @runTest => @assert.includes m.getSubclassesOf('Employee'), 'CEO'
        @runTest => @assert.includes m.getSubclassesOf('Thing'), 'Address'
        @runTest => @assert.eql things, m.getSubclassesOf('Thing')

exports['#getPathInfo'] = async 1, -> @gotModel.fail(@failN 1).done @testCB (m) =>
    @assert.includes Model.NUMERIC_TYPES, m.makePath('Employee.age').getType()


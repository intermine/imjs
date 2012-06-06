{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold}  = require '../../src/shiv'

exports['can append to a list from a query'] = asyncTest 4, (beforeExit, assert) ->
    younger_emps = omap((k, v) -> [k, if k is 'where' then {age: {le: 50}} else v]) older_emps
    all_emps = select: ['id'], from: 'Employee', where: {age: 'is not null'}
    @service.query all_emps, (all) => all.count (count) => @service.query older_emps, (oq) =>
        oq.saveAsList name: 'temp-olders', tags: ['js', 'node'], (ol) =>
            startSize = ol.size
            @service.query younger_emps, (yq) => yq.appendToList ol, (updated) =>
                updated.del().done(() => @runTest () -> assert.ok true)
                             .fail(() => @runTest () -> assert.ok false)
                             .always () =>
                    @runTest () -> assert.ok startSize < updated.size, "Size isn't any bigger now"
                    @runTest () -> assert.eql ol.size, updated.size
                    @runTest () -> assert.eql count, updated.size, "ALL: #{ count }, appended size: #{ updated.size }"


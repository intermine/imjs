{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold, invoke}  = require '../../src/shiv'
$ = require 'underscore.deferred'


exports['can append to a list from a query'] = asyncTest 3, (beforeExit, assert) ->

    # I can't seem to get the teardown to run :(
    @service.fetchList('temp-olders').then(invoke 'del')

    younger_emps = omap((k, v) -> [k, if k is 'where' then {age: {le: 50}} else v]) older_emps
    all_emps = select: ['id'], from: 'Employee', where: {age: 'is not null'}
    newListProps = name: 'temp-olders', tags: ['js', 'node']
    delendum = null

    promA = @service.count(all_emps)
    promC = @service.query(younger_emps)
    promB = @service.query(older_emps).then(invoke 'saveAsList', newListProps)

    $.when(promA, promB, promC).done (all_count, list, yq) => #.fail(@failN 3)
        delendum = list
        startSize = list.size
        yq.appendToList(list).done (updated) =>
            @runTest -> assert.ok startSize < updated.size, "Size isn't any bigger now"
            @runTest -> assert.eql list.size, updated.size
            @runTest -> assert.eql all_count, updated.size, "ALL: #{ count }, appended size: #{ updated.size }"


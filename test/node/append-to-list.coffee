{asyncTest, older_emps, clearTheWay} = require './lib/service-setup'
{omap, fold, invoke}  = require '../../src/util'
$ = require 'underscore.deferred'

name = 'temp-olders'
tags = ['js', 'node']
younger_emps = omap((k, v) -> [k, if k is 'where' then {age: {le: 50}} else v]) older_emps
all_emps = select: ['id'], from: 'Employee', where: {age: 'is not null'}

exports['can append to a list from a query'] = asyncTest 3, (beforeExit, A) ->
    setup   = => clearTheWay(@service, name)
    cleanUp = => @service.fetchList(name).then(invoke 'del')
    run     = =>
        gotCount   = @service.count all_emps
        builtQuery = @service.query younger_emps
        madeList   = @service.query(older_emps).then(invoke 'saveAsList', {name, tags})
        $.when(gotCount, builtQuery, madeList).then (total, yq, list) =>
            startSize = list.size # copy the size so we can check it later.
            yq.appendToList(list)
              .done(@testCB (l) -> A.ok startSize < l.size, "Size isn't any bigger now")
              .done(@testCB (l) -> A.eql list.size, l.size, "Old object and new aren't in synch")
              .done(@testCB (l) -> A.eql total, l.size, "ALL: #{ total }, OLD+YOUNG: #{ l.size }")

    setup().then(run).always(cleanUp)

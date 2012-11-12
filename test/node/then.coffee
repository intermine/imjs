# Tests that check that our chosen node promises library has the expected behaviour.
# This test just makes sure that contract assumed by this code is fulfilled
# by the library we employ.

$ = require 'underscore.deferred'
{asyncTest} = require './lib/service-setup'

c = 1
VOID = -> null
TRANSFORM = (x) -> x + '-TRANSFORMED'

done = $.Deferred -> @resolve 'DONE'
fertig = $.Deferred -> @resolve 'FERTIG'
failed = $.Deferred -> @reject 'BOOM!'

exports['done does not alter the promise'] = asyncTest 1, (be, assert) ->
    done.done(TRANSFORM)
        .done((x) => @runTest -> assert.eql x, 'DONE')
        .fail(@fail)

exports['Done executes multiple callbacks, without altering the result'] = asyncTest 3, (be, assert) ->
    done.done(@pass, TRANSFORM, @pass)
        .done((x) => @runTest -> assert.eql x, 'DONE')
        .fail(@fail)

exports['then is a pipe for values'] = asyncTest 1, (be, assert) ->
    done.done(VOID).then(TRANSFORM)
        .done((x) => @runTest -> assert.eql x, 'DONE-TRANSFORMED')
        .fail(@fail)

exports['pipe is a pipe for values'] = asyncTest 1, (be, assert) ->
    done.done(VOID).pipe(TRANSFORM)
        .done((x) => @runTest -> assert.eql x, 'DONE-TRANSFORMED')
        .fail(@fail)

exports['Inner promises bubble out: resolution'] = asyncTest 1, (be, assert) ->
    done.done(VOID).then(-> fertig)
        .done((x) => @runTest -> assert.eql x, 'FERTIG')
        .fail(@fail)

exports['Inner promises bubble out: rejection'] = asyncTest 1, (be, assert) ->
    done.done(VOID).then(-> failed)
        .done(@fail)
        .fail((x) => @runTest -> assert.eql x, 'BOOM!')

exports['Inner promises bubble out when piped: resolution'] = asyncTest 1, (be, assert) ->
    done.done(VOID).pipe(-> fertig)
        .done((x) => @runTest -> assert.eql x, 'FERTIG')
        .fail(@fail)

exports['Inner promises bubble out when piped: rejection'] = asyncTest 1, (be, assert) ->
    done.done(VOID).pipe(-> failed)
        .done(@fail)
        .fail((x) => @runTest -> assert.eql x, 'BOOM!')

exports['Errors bubble all the way out.'] = asyncTest 1, (be, assert) ->
    failed.done(VOID).then(TRANSFORM).done(@fail)
        .fail((x) => @runTest -> assert.eql x, 'BOOM!')


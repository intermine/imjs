{Service} = require '../../lib/service'
{testCase, asyncTestCase} = require './lib/util'
{get, invoke} = require '../../src/util'

test = asyncTestCase -> ctx =
    service: new Service(root: 'www.flymine.org/query')

query = -> q =
    from: 'Gene',
    select: ['*'],
    where:
        symbol: ['eve', 'zen', 'r', 'bib']

exports['can get fasta'] = test 1, (beforeExit, A) ->
    @service.query query(), (q) =>
        q.getFASTA @testCB (fa) ->
            A.ok fa.split('>').length >= 4

exports['can pipe fasta'] = test 1, (beforeExit, A) ->
    @service.query(query())
        .then(invoke 'getFASTA')
        .then((fa) -> fa.split('>').length)
        .done @testCB (n) -> A.ok n >= 4


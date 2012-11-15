{Service} = require '../../lib/service'
{testCase, asyncTestCase} = require './lib/util'
{invoke} = require '../../src/shiv'

test = asyncTestCase -> ctx =
    service: new Service(root: 'www.flymine.org/query')

query = -> q =
    select: ['*']
    from: 'Gene'
    where:
        symbol: ['eve', 'zen', 'r', 'bib']

getTest = (A, min, max) -> (gff3) ->
    lines = gff3.split('\n').length
    msg = """
        Expected to get gff3 with between #{ min } and #{ max }
        lines. But got #{ lines } lines.
    """
    A.ok min <= lines <= max, msg

exports['can get gff3'] = test 1, (beforeExit, assert) ->
    @service.query query(), (q) =>
        q.getGFF3 @testCB getTest assert, 4, 6

exports['can get gff3 with exons'] = test 1, (beforeExit, assert) ->
    q = query()
    q.select.push('exons.*')
    @service.query q, (q) =>
        q.getGFF3 @testCB getTest assert, 20, 25

exports['can pipe gff3'] = test 1, (beforeExit, assert) ->
    @service.query(query())
       .then(invoke 'getGFF3')
       .then @testCB getTest assert, 4, 6


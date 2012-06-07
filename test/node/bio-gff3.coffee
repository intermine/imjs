{Service} = require '../../lib/service'
{testCase, asyncTestCase} = require './lib/util'

test = asyncTestCase () ->
    s = new Service root: 'www.flymine.org/query'
    {service: s}

cons = symbol: ['eve', 'zen', 'r', 'bib']

exports['can get gff3'] = test 1, (beforeExit, assert) ->
    @service.query from: 'Gene', select: ['*'], where: cons, (q) =>
        q.getGFF3 (gff3) => @runTest () -> assert.ok 4 <= gff3.split('\n').length <= 6


exports['can get gff3 with exons'] = test 1, (beforeExit, assert) ->
    @service.query from: 'Gene', select: ['*', 'exons.symbol'], where: cons, (q) =>
        q.getGFF3 (gff3) => @runTest () -> assert.ok 20 <= gff3.split('\n').length <= 25


{Service} = require './lib/fixture'
$ = require 'underscore.deferred'
{prepare, eventually} = require './lib/utils'

countRecords = (gff3) ->
  (l for l in gff3.split(/\n/) when l.length and not /^#/.test(l.trim())).length

describe 'GFF3 Queries', ->

  # TODO: ideally this should point at a more stable mine.
  service = new Service root: 'www.flymine.org/query'

  describe 'implicitly constrained', ->
    opts =
      from: 'Gene'
      select: ['symbol', 'pathways.name']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']

    @beforeAll prepare -> service.query(opts).then (q) ->
      q.summarise('symbol').then (_, stats) -> $.when stats, q.getGFF3()

    it 'should find only one gene, due to the pathways', eventually (stats, gff3) ->
      stats.uniqueValues.should.equal 1

    it 'should find only one gff3 record, due to the pathways', eventually (stats, gff3) ->
      countRecords(gff3).should.equal 1

  describe 'outer joined', ->
    opts =
      from: 'Gene'
      select: ['symbol', 'pathways.name']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']
      joins: ['pathways']

    @beforeAll prepare -> service.query(opts).then (q) ->
      q.summarise('symbol').then (_, stats) -> $.when stats, q.getGFF3()

    it 'should find 5 genes', eventually (stats, gff3) ->
      stats.uniqueValues.should.equal 5

    it 'should find 5 gff3 records', eventually (stats, gff3) ->
      countRecords(gff3).should.equal 5

  describe 'unconstrained', ->
    opts =
      from: 'Gene'
      select: ['symbol']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']

    @beforeAll prepare -> service.query(opts).then (q) ->
      q.summarise('symbol').then (_, stats) -> $.when stats, q.getGFF3()

    it 'should find all genes', eventually (stats, gff3) ->
      stats.uniqueValues.should.equal 5

    it 'should find 5 gff3 records', eventually (stats, gff3) ->
      countRecords(gff3).should.equal 5

  describe 'with exons', ->
    opts =
      from: 'Gene'
      select: ['symbol', 'exons.symbol']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']
      joins: ['exons']

    @beforeAll prepare -> service.query(opts).then (q) ->
      q.summarise('symbol').then (_, stats) -> $.when stats, q.getGFF3()

    it 'should find all genes', eventually (stats, gff3) ->
      stats.uniqueValues.should.equal 5

    it 'should find more than 5 gff3 records', eventually (stats, gff3) ->
      countRecords(gff3).should.be.above 5



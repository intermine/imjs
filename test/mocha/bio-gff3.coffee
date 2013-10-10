{Service} = require './lib/fixture'
$ = require 'underscore.deferred'
{prepare, eventually} = require './lib/utils'

countRecords = (gff3) ->
  (l for l in gff3.split(/\n/) when l.length and not /^#/.test(l.trim())).length

describe 'GFF3 Queries', ->

  @timeout 10000

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

    it 'should find only two genes, due to the pathways', eventually (stats, gff3) ->
      stats.uniqueValues.should.equal 2

    it 'should find only two gff3 record, due to the pathways', eventually (stats, gff3) ->
      countRecords(gff3).should.equal 2

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

  describe 'with extra attributes', ->
    opts =
      from: 'Gene'
      select: ['symbol']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']

    @beforeAll prepare ->
      beta = new Service root: 'www.flymine.org/query'
      qp = beta.query(opts)
      qp.then (q) ->
        statsp = q.summarise('symbol').then (_, stats) -> stats
        gff3p = q.getGFF3 view: ['organism.name', 'length']
        $.when statsp, gff3p

    it 'should find all genes', eventually (stats, gff3) ->
      stats.uniqueValues.should.equal 5

    it 'should find 5 gff3 records', eventually (stats, gff3) ->
      countRecords(gff3).should.equal 5

    it 'the records should have the extra attributes', eventually (stats, gff3) ->
      for line in gff3.split("\n") when line.length and not /^#/.test line
        col9 = line.split(/\t/)[8]
        col9.should.match /organism.name/
        col9.should.match /length/

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



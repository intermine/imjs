Fixture              = require './lib/fixture'
{cleanSlate, deferredTest, prepare, always, clear, eventually, shouldFail} = require './lib/utils'
{prepare, eventually, always} = require './lib/utils'
should               = require 'should'

describe 'Service', ->

  {service} = new Fixture()

  describe '#values()', ->

    it 'should fail', shouldFail service.values

  describe '#values("Foo.bar")', ->

    it 'should fail', shouldFail -> service.values 'Foo.bar'

  describe '#values("Company.name")', ->

    @beforeAll prepare -> service.values 'Company.name'

    it 'should get a list of seven values', eventually (values) ->
      values.length.should.equal 7

    it 'should include Wernham-Hogg', eventually (values) ->
      (v.value for v in values).should.include 'Wernham-Hogg'

  describe '#values(Path("Company.name"))', ->

    @beforeAll prepare -> service.fetchModel().then (m) ->
      service.values m.makePath 'Company.name'

    it 'should get a list of seven values', eventually (values) ->
      values.length.should.equal 7

    it 'should include Wernham-Hogg', eventually (values) ->
      (v.value for v in values).should.include 'Wernham-Hogg'

  describe '#values("Department.employees.name")', ->

    @beforeAll prepare -> service.values 'Department.employees.name'

    it 'should get a list of 132 values', eventually (values) ->
      values.length.should.equal 132
      
    it 'should include David-Brent', eventually (values) ->
      (v.value for v in values).should.include 'David Brent'

  describe '#values("Department.employees.name")', ->

    @beforeAll prepare -> service.fetchModel().then (m) ->
      service.values m.makePath 'Department.employees.name'

    it 'should get a list of 132 values', eventually (values) ->
      
    it 'should include David-Brent', eventually (values) ->
      (v.value for v in values).should.include 'David Brent'

  describe '#values("Department.employees.name", {"Department.employees": "CEO"})', ->

    @beforeAll prepare -> service.values 'Department.employees.name', 'Department.employees': 'CEO'

    it 'should get a list of six values', eventually (values) ->
      values.length.should.equal 6
    
    it 'should not include David-Brent', eventually (values) ->
      (v.value for v in values).should.not.include 'David Brent'

    it "should include B'wah Hah Hah", eventually (values) ->
      (v.value for v in values).should.include "Charles Miner"

  describe '#values(Path("Department.employees.name", {"Department.employees": "CEO"}))', ->

    @beforeAll prepare -> service.fetchModel().then (m) ->
      service.values m.makePath 'Department.employees.name', 'Department.employees': 'CEO'

    it 'should get a list of six values', eventually (values) ->
      values.length.should.equal 6
    
    it 'should not include David-Brent', eventually (values) ->
      (v.value for v in values).should.not.include 'David Brent'

    it "should include B'wah Hah Hah", eventually (values) ->
      (v.value for v in values).should.include "Charles Miner"


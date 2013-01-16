should     = require 'should'
{Model}    = require '../../src/model'
{PathInfo} = require '../../src/path'

{TESTMODEL} = require './data/model'

things = ["Thing","Employable","Contractor","Employee","Manager","CEO","Address"]

describe 'Model', ->

  describe 'new', ->

    testmodel = new Model TESTMODEL.model

    it 'returns a Model', ->
      should.exist testmodel
      testmodel.should.be.an.instanceOf Model

    it 'should have classes', ->
      testmodel.should.have.property 'classes'

  describe '#getSubclassesOf', ->

    testmodel = new Model TESTMODEL.model

    it 'should find that CEO is one of the subclasses of Manager', ->
      testmodel.getSubclassesOf('Manager').should.include('CEO')

    it 'should find that CEO is one of the subclasses of HasAddress', ->
      testmodel.getSubclassesOf('HasAddress').should.include('CEO')

    it 'should find that CEO is one of the subclasses of Employable', ->
      testmodel.getSubclassesOf('Employable').should.include('CEO')

    it 'should find all the classes that are things', ->
      testmodel.getSubclassesOf('Thing').should.eql(things)

    it 'should find that Addresses are not per se Employable', ->
      testmodel.getSubclassesOf('Employable').should.not.include('Address')

  describe '#findCommonType', ->

    testmodel = new Model TESTMODEL.model
    
    it 'should determine that the common class of a class is itself', ->
      testmodel.findCommonType(['Employee']).should.equal('Employee')

    it 'should say the common class of two examples of the same class is that class', ->
      testmodel.findCommonType(['Employee', 'Employee']).should.equal('Employee')

    it 'should say the common type of a class and its super-type is the super-type', ->
      testmodel.findCommonType(['Manager', 'Employee']).should.equal('Employee')

    it 'should say the common type of a class and one of its sub-types is the super-type', ->
      testmodel.findCommonType(['Manager', 'CEO']).should.equal('Manager')

    it 'should return a non-existent value for incompatible classes', ->
      should.not.exist testmodel.findCommonType(['Department', 'CEO'])

    it 'should return the mutual super class of compatible classes', ->
      testmodel.findCommonType(['CEO', 'Address']).should.equal('Thing')

    it 'should handle more than two classes', ->
      types = ['Employee', 'Contractor', 'Manager']
      testmodel.findCommonType(types).should.equal('Employable')

    it 'should determine that the set of all things are things', ->
      testmodel.findCommonType(things).should.equal('Thing')

  describe '#getPathInfo', ->

    testmodel = new Model TESTMODEL.model

    it 'should be able to make a path', ->
      path = testmodel.makePath('Employee.age')
      should.exist path
      path.should.be.an.instanceOf PathInfo

  describe 'NUMERIC_TYPES', ->

    it 'should include whole number types', ->
      Model.NUMERIC_TYPES.should.include('int')
      Model.NUMERIC_TYPES.should.include('Integer')
      Model.NUMERIC_TYPES.should.include('long')
      Model.NUMERIC_TYPES.should.include('Long')

    it 'should include fractional types', ->
      Model.NUMERIC_TYPES.should.include('float')
      Model.NUMERIC_TYPES.should.include('Float')
      Model.NUMERIC_TYPES.should.include('double')
      Model.NUMERIC_TYPES.should.include('Double')






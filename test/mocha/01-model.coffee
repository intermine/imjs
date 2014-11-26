should     = require 'should'
{Model}    = require './lib/fixture'

{TESTMODEL} = require '../data/model'

things = ["Thing","Employable","Contractor","Employee","Manager","CEO","Address"]

describe 'Model', ->

  describe 'new', ->

    testmodel = new Model TESTMODEL.model

    it 'returns a Model', ->
      should.exist testmodel
      testmodel.should.be.an.instanceOf Model

    it 'should have classes', ->
      testmodel.should.have.property 'classes'

  describe 'attempting to load bad data', ->

    attempt = -> Model.load {classes: {Foo: {attributes: {}}}}

    it 'should throw some kind of error', ->
      attempt.should.throwError()

  describe '#getAncestorsOf', ->

    testmodel = Model.load TESTMODEL.model

    describe 'attempting to get the ancestry of a non-class', ->
      attempt = -> testmodel.getAncestorsOf 'Foo'

      it 'should throw a helpful error', ->
        attempt.should.throw /not a table/

  describe '#findSharedAncestor', ->

    testmodel = Model.load TESTMODEL.model

    describe 'The shared ancestor of a class and null', ->

      ancestor = testmodel.findSharedAncestor 'Employee', null

      it 'should not exist', ->
        should.not.exist ancestor

    describe 'The shared ancestor of a class and itself', ->
      ancestor = testmodel.findSharedAncestor 'Employable', 'Employable'

      it 'should be non-null', ->
        should.exist ancestor

      it 'should be itself', ->
        ancestor.should.equal 'Employable'

    describe 'The shared ancestor of a class and one of its ancestors', ->
      ancestor = testmodel.findSharedAncestor 'CEO', 'Employable'

      it 'is the ancestor', ->
        ancestor.should.equal 'Employable'

    describe 'The shared ancestor of a class and one of its sub-classes', ->
      ancestor = testmodel.findSharedAncestor 'Employable', 'CEO'

      it 'is the class', ->
        ancestor.should.equal 'Employable'

    describe 'The shared ancestor of cousins', ->
      ancestor = testmodel.findSharedAncestor 'Employee', 'Company'

      it 'is the closest common ancestor', ->
        ancestor.should.equal 'HasAddress'

  describe '#getSubclassesOf', ->

    testmodel = new Model TESTMODEL.model

    describe 'attempting to get subclasses of a non-class', ->
      attempt = -> testmodel.getSubclassesOf null

      it 'should throw a helpful error', ->
        attempt.should.throw /not a table/

    describe 'the subclasses of Manager', ->
      managerTypes = testmodel.getSubclassesOf 'Manager'

      it 'should include "CEO"', ->
        managerTypes.should.containEql('CEO')

    describe 'the subclasses of HasAddress', ->
      addressables = testmodel.getSubclassesOf 'HasAddress'

      it 'should include "CEO"', ->
        addressables.should.containEql 'CEO'

      it 'should include "Company"', ->
        addressables.should.containEql 'Company'

    describe 'the subclasses of Employable', ->
      employables = testmodel.getSubclassesOf 'Employable'

      it 'should include "CEO"', ->
        employables.should.containEql 'CEO'

      it 'should include "Contractor"', ->
        employables.should.containEql 'Contractor'

      it 'should not include "Address"', ->
        employables.should.not.containEql 'Address'

    describe 'Things', ->
      foundThings = testmodel.getSubclassesOf 'Thing'

      it 'should include all the things that are things', ->
        foundThings.should.eql things

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
      path.should.have.properties [
        'end', 'getType', 'getDisplayName', 'append', 'getParent',
        'isAttribute', 'isReference', 'isCollection', 'isRoot'
      ]

  describe 'NUMERIC_TYPES', ->

    it 'should include whole number types', ->
      Model.NUMERIC_TYPES.should.containEql('int')
      Model.NUMERIC_TYPES.should.containEql('Integer')
      Model.NUMERIC_TYPES.should.containEql('long')
      Model.NUMERIC_TYPES.should.containEql('Long')

    it 'should include fractional types', ->
      Model.NUMERIC_TYPES.should.containEql('float')
      Model.NUMERIC_TYPES.should.containEql('Float')
      Model.NUMERIC_TYPES.should.containEql('double')
      Model.NUMERIC_TYPES.should.containEql('Double')






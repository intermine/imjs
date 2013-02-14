lib = if process.env.IMJS_COV then 'build-cov' else 'build'

{Model} = require "../../#{ lib }/model"
{PathInfo} = require "../../#{ lib }/path"

{TESTMODEL} = require './data/model'

testmodel = new Model TESTMODEL.model

describe 'PathInfo', ->

  describe 'Illegal paths', ->

    it 'should be detected upon creation', ->
      (-> testmodel.makePath 'Foo.bar').should.throw()
      (-> testmodel.makePath 'Department.employees.seniority').should.throw()

  describe 'root', ->
    path = testmodel.makePath 'Employee'

    it 'should stringify with toString()', ->
      path.toString().should.equal('Employee')
    it 'should stringify with toPathString()', ->
      path.toPathString().should.equal('Employee')
    it 'should stringify with string concatenation', ->
      ('' + path).should.equal('Employee')

    describe '#getType()', -> it 'should report an appropriate type', ->
      path.getType().should.have.property('name', 'Employee')

    describe '#containsCollection()', -> it 'should not contain a collection', ->
      path.containsCollection().should.be.false

    describe '#getParent()', -> it 'should throw an error', ->
      path.getParent.should.throw()

    describe '#append(field)', ->

      it 'should return a new child path', ->
        path.append('id').getType().should.equal('Integer')

      it "should throw if the field doesn't exist", ->
        (-> path.append 'postCode').should.throw()

    describe '#isRoot()', -> it 'should return true', ->
      path.isRoot().should.be.true

    describe '#isAttribute()', -> it 'should return false', ->
      path.isAttribute().should.be.false

    describe '#isReference', -> it 'should return false', ->
      path.isReference().should.be.false

    describe '#isCollection', -> it 'should return false', ->
      path.isCollection().should.be.false

    describe '#isClass', -> it 'should return true', ->
      path.isClass().should.be.true

    describe '#isa(type)', ->
      it 'should say it is an Employee', -> path.isa('Employee').should.be.true

      it 'should say it is a Thing', -> path.isa('Thing').should.be.true

      it 'should not say it is a Department', -> path.isa('Department').should.not.be.true

      it 'should not say it is an int', -> path.isa('int').should.not.be.true

  describe 'Simple attribute', ->
    path = testmodel.makePath 'Employee.age'

    it 'should stringify with toString()', ->
      path.toString().should.equal('Employee.age')
    it 'should stringify with toPathString()', ->
      path.toPathString().should.equal('Employee.age')
    it 'should stringify with string concatenation', ->
      ('' + path).should.equal('Employee.age')

    describe '#getType()', -> it 'should report an appropriate type', ->
      path.getType().should.equal('int')

    describe '#containsCollection()', -> it 'should not contain a collection', ->
      path.containsCollection().should.be.false

    describe '#getParent()', -> it 'should have a parent of the right type', ->
      path.getParent().getType().name.should.equal('Employee')

    describe '#append(field)', -> it 'should throw an error', ->
      path.append.should.throw()

    describe '#isRoot()', -> it 'should return false', ->
      path.isRoot().should.be.false

    describe '#isAttribute()', -> it 'should return true', ->
      path.isAttribute().should.be.true

    describe '#isReference', -> it 'should return false', ->
      path.isReference().should.be.false

    describe '#isCollection', -> it 'should return false', ->
      path.isCollection().should.be.false

    describe '#isClass', -> it 'should return false', ->
      path.isClass().should.be.false

    describe '#isa(type)', ->
      it 'should not say it is an Employee', -> path.isa('Employee').should.not.be.true

      it 'should not say it is a Thing', -> path.isa('Thing').should.not.be.true

      it 'should not say it is a Department', -> path.isa('Department').should.not.be.true

      it 'should say it is an int', -> path.isa('int').should.be.true

  describe 'Simple reference', ->
    path = testmodel.makePath 'Employee.address'

    it 'should stringify with toString()', ->
      path.toString().should.equal('Employee.address')
    it 'should stringify with toPathString()', ->
      path.toPathString().should.equal('Employee.address')
    it 'should stringify with string concatenation', ->
      ('' + path).should.equal('Employee.address')

    describe '#getType()', -> it 'should report an appropriate type', ->
      path.getType().name.should.equal('Address')

    describe '#containsCollection()', -> it 'should not contain a collection', ->
      path.containsCollection().should.be.false

    describe '#getParent()', -> it 'should have a parent of the right type', ->
      path.getParent().getType().name.should.equal('Employee')

    describe '#append(field)', ->
      
      it 'should return the appropriate child path', ->
        path.append('id').getType().should.equal('Integer')

      it "should throw if the field doesn't exist", ->
        (-> path.append 'postCode').should.throw()

    describe '#isRoot()', -> it 'should return false', ->
      path.isRoot().should.be.false

    describe '#isAttribute()', -> it 'should return false', ->
      path.isAttribute().should.be.false

    describe '#isReference', -> it 'should return true', ->
      path.isReference().should.be.true

    describe '#isCollection', -> it 'should return false', ->
      path.isCollection().should.be.false

    describe '#isClass', -> it 'should return true', ->
      path.isClass().should.be.true

    describe '#isa(type)', ->
      it 'should not say it is an Employee', -> path.isa('Employee').should.not.be.true

      it 'should say it is a Thing', -> path.isa('Thing').should.be.true

      it 'should not say it is a Department', -> path.isa('Department').should.not.be.true

      it 'should not say it is an int', -> path.isa('int').should.not.be.true

  describe 'Simple collection', ->
    path = testmodel.makePath 'Department.employees'

    it 'should stringify with toString()', ->
      path.toString().should.equal('Department.employees')
    it 'should stringify with toPathString()', ->
      path.toPathString().should.equal('Department.employees')
    it 'should stringify with string concatenation', ->
      ('' + path).should.equal('Department.employees')

    describe '#getType()', -> it 'should report an appropriate type', ->
      path.getType().name.should.equal('Employee')

    describe '#containsCollection()', -> it 'should contain a collection', ->
      path.containsCollection().should.be.true

    describe '#getParent()', -> it 'should have a parent of the right type', ->
      path.getParent().getType().name.should.equal('Department')

    describe '#append(field)', ->
      
      it 'should return the appropriate child path', ->
        path.append('id').getType().should.equal('Integer')

      it "should throw if the field doesn't exist", ->
        (-> path.append 'postCode').should.throw()

    describe '#isRoot()', -> it 'should return false', ->
      path.isRoot().should.be.false

    describe '#isAttribute()', -> it 'should return false', ->
      path.isAttribute().should.be.false

    describe '#isReference', -> it 'should return true', ->
      path.isReference().should.be.true

    describe '#isCollection', -> it 'should return true', ->
      path.isCollection().should.be.true

    describe '#isClass', -> it 'should return true', ->
      path.isClass().should.be.true

    describe '#isa(type)', ->
      it 'should say it is an Employee', -> path.isa('Employee').should.be.true

      it 'should say it is a Thing', -> path.isa('Thing').should.be.true

      it 'should not say it is a Department', -> path.isa('Department').should.not.be.true

      it 'should not say it is an int', -> path.isa('int').should.not.be.true

  describe 'Subclassed path', ->
    path = testmodel.makePath 'Department.employees', {'Department.employees': 'CEO'}

    describe '#getType()', -> it 'should report the subclass', ->
      path.getType().name.should.equal('CEO')

    describe '#containsCollection()', -> it 'should contain a collection', ->
      path.containsCollection().should.be.true

    describe '#getParent()', -> it 'should have a parent of the right type', ->
      path.getParent().getType().name.should.equal('Department')

    describe '#append(field)', ->
      
      it 'should return the appropriate child path', ->
        path.append('seniority').getType().should.equal('Integer')
        path.append('company').getType().name.should.equal('Company')

      it "should throw if the field doesn't exist", ->
        (-> path.append 'postCode').should.throw()

    describe '#isRoot()', -> it 'should return false', ->
      path.isRoot().should.be.false

    describe '#isAttribute()', -> it 'should return false', ->
      path.isAttribute().should.be.false

    describe '#isReference', -> it 'should return true', ->
      path.isReference().should.be.true

    describe '#isCollection', -> it 'should return true', ->
      path.isCollection().should.be.true

    describe '#isClass', -> it 'should return true', ->
      path.isClass().should.be.true

    describe '#isa(type)', ->
      it 'should say it is an Employee', -> path.isa('Employee').should.be.true

      it 'should say it is a Thing', -> path.isa('Thing').should.be.true

      it 'should not say it is a Department', -> path.isa('Department').should.not.be.true

      it 'should not say it is an int', -> path.isa('int').should.not.be.true

  describe 'Long reference chain', ->
    path = testmodel.makePath 'Employee.department.company.address'

    it 'should stringify with toString()', ->
      path.toString().should.equal('Employee.department.company.address')
    it 'should stringify with toPathString()', ->
      path.toPathString().should.equal('Employee.department.company.address')
    it 'should stringify with string concatenation', ->
      ('' + path).should.equal('Employee.department.company.address')

    describe '#getType()', -> it 'should report an appropriate type', ->
      path.getType().name.should.equal('Address')

    describe '#containsCollection()', -> it 'should not contain a collection', ->
      path.containsCollection().should.not.be.true

    describe '#getParent()', -> it 'should have a parent of the right type', ->
      path.getParent().getType().name.should.equal('Company')

    describe '#append(field)', ->
      
      it 'should return the appropriate child path', ->
        path.append('id').getType().should.equal('Integer')

      it "should throw if the field doesn't exist", ->
        (-> path.append 'postCode').should.throw()

    describe '#isRoot()', -> it 'should return false', ->
      path.isRoot().should.be.false

    describe '#isAttribute()', -> it 'should return false', ->
      path.isAttribute().should.be.false

    describe '#isReference', -> it 'should return true', ->
      path.isReference().should.be.true

    describe '#isCollection', -> it 'should return false', ->
      path.isCollection().should.be.false

    describe '#isClass', -> it 'should return true', ->
      path.isClass().should.be.true

    describe '#isa(type)', ->
      it 'should not say it is an Employee', -> path.isa('Employee').should.not.be.true

      it 'should say it is a Thing', -> path.isa('Thing').should.be.true

      it 'should not say it is a Department', -> path.isa('Department').should.not.be.true

      it 'should not say it is an int', -> path.isa('int').should.not.be.true

  describe 'Long reference with collection chain', ->
    path = testmodel.makePath 'Company.departments.manager.address'

    it 'should stringify with toString()', ->
      path.toString().should.equal('Company.departments.manager.address')
    it 'should stringify with toPathString()', ->
      path.toPathString().should.equal('Company.departments.manager.address')
    it 'should stringify with string concatenation', ->
      ('' + path).should.equal('Company.departments.manager.address')

    describe '#getType()', -> it 'should report an appropriate type', ->
      path.getType().name.should.equal('Address')

    describe '#containsCollection()', -> it 'should contain a collection', ->
      path.containsCollection().should.be.true

    describe '#getParent()', -> it 'should have a parent of the right type', ->
      path.getParent().getType().name.should.equal('Manager')

    describe '#append(field)', ->
      
      it 'should return the appropriate child path', ->
        path.append('id').getType().should.equal('Integer')

      it "should throw if the field doesn't exist", ->
        (-> path.append 'postCode').should.throw()

    describe '#isRoot()', -> it 'should return false', ->
      path.isRoot().should.be.false

    describe '#isAttribute()', -> it 'should return false', ->
      path.isAttribute().should.be.false

    describe '#isReference', -> it 'should return true', ->
      path.isReference().should.be.true

    describe '#isCollection', -> it 'should return false', ->
      path.isCollection().should.not.be.true

    describe '#isClass', -> it 'should return true', ->
      path.isClass().should.be.true

    describe '#isa(type)', ->
      it 'should not say it is an Employee', -> path.isa('Employee').should.not.be.true

      it 'should say it is a Thing', -> path.isa('Thing').should.be.true

      it 'should not say it is a Department', -> path.isa('Department').should.not.be.true

      it 'should not say it is an int', -> path.isa('int').should.not.be.true


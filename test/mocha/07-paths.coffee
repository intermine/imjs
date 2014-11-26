if process.env.IMJS_COV
  covDir = '../../build-cov'
  {Model} = require covDir + "/model"
  {PathInfo} = require covDir + "/path"
else
  {Model} = require "../../build/service"
  {PathInfo} = require "../../build/path"

Promise = require 'promise'

{shouldFail, prepare, eventually} = require './lib/utils'
Fixture = require './lib/fixture'

{TESTMODEL} = require '../data/model'

testmodel = new Model TESTMODEL.model
{service} = new Fixture
testmodel.service = service

describe 'PathInfo', ->

  @afterEach PathInfo.flushCache

  describe 'Illegal paths', ->

    it 'should be detected upon creation', ->
      (-> testmodel.makePath 'Foo.bar').should.throw()
      (-> testmodel.makePath 'Department.employees.seniority').should.throw()

  describe 'root', ->
    path = null
    
    @beforeEach -> path = testmodel.makePath 'Employee'

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

    describe '#getChildNodes()', ->

      it 'should find 10 child nodes', ->
        path.getChildNodes().length.should.equal 10

      it 'should find Employee.department', ->
        (n.toString() for n in path.getChildNodes()).should.containEql 'Employee.department'

      it 'should produce nodes that can find their parent', ->
        n.getParent().equals(path).should.be.true for n in path.getChildNodes()

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

    describe '#getDisplayName', ->

      describe 'promise API', ->
        @beforeAll prepare path.getDisplayName

        it 'should be a nice human readable string', eventually (name) ->
          name.should.equal "Employee > Years Alive"

      describe 'callback api', ->
        
        it 'should yield the name', (done) ->
          path.getDisplayName (err, name) ->
            return done err if err?
            try
              name.should.equal "Employee > Years Alive"
              done()
            catch e
              done e

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

  describe 'A path with a custom name', ->
    path = testmodel.makePath 'Company.departments.manager.address'
    path.displayName = "FOO"

    describe '#getDisplayName', ->

      @beforeAll prepare path.getDisplayName
      @afterEach PathInfo.flushCache

      it 'should promise to return the name we gave it', eventually (name) ->
        name.should.equal "FOO"

  describe 'Long reference with collection chain', ->

    PathInfo.flushCache()

    path = testmodel.makePath 'Company.departments.manager.address'

    it 'should stringify with toString()', ->
      path.toString().should.equal('Company.departments.manager.address')
    it 'should stringify with toPathString()', ->
      path.toPathString().should.equal('Company.departments.manager.address')
    it 'should stringify with string concatenation', ->
      ('' + path).should.equal('Company.departments.manager.address')

    describe '#getPathInfo', ->

      @beforeAll prepare path.getDisplayName

      it 'should promise to return a name', eventually (name) ->
        name.should.equal "Company > Departments > Manager > Address"

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

describe 'Two similar paths', ->

  pathA = testmodel.makePath 'Employee.name'
  pathB = testmodel.makePath 'Employee.name'

  it 'should equal each other', ->
    pathA.equals(pathB).should.be.true

  describe 'their names', ->

    @beforeAll prepare -> Promise.all (p.getDisplayName() for p in [pathA, pathB])

    it 'should be the same', eventually ([a, b]) ->
      a.should.eql b

describe 'The path of a poor person', ->

  path = testmodel.makePath 'Broke'

  @beforeAll prepare -> path.getDisplayName()

  it 'should say this person is poor', eventually (name) ->
    name.should.eql 'Poor Person'


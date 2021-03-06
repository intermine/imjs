if process.env.IMJS_COV
  covDir = '../../build-cov'
  {Model} = require covDir + "/model"
  {PathInfo} = require covDir + "/path"
else
  {Model} = require "../../build/service"
  {PathInfo} = require "../../build/path"

should = require 'should'
{unitTests, integrationTests, bothTests} = require './lib/segregation'
{setupRecorder, stopRecorder} = require './lib/mock'
{setupBundle} = require './lib/mock'

{shouldFail, prepare, eventually} = require './lib/utils'
Fixture = require './lib/fixture'

{TESTMODEL} = require '../data/model'

testmodel = new Model TESTMODEL.model
{service} = new Fixture
testmodel.service = service

bothTests() && describe 'PathInfo', ->
  setupBundle '07-paths.1.json'
  # setupRecorder()
  @afterAll ->
    # stopRecorder 'dummy.json'

  @afterEach PathInfo.flushCache

  unitTests() && describe 'Illegal paths', ->

    it 'should be detected upon creation', ->
      (-> testmodel.makePath 'Foo.bar').should.throw()
      (-> testmodel.makePath 'Department.employees.seniority').should.throw()

  unitTests() && describe 'root', ->
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

  unitTests() && describe 'Simple attribute', ->
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
      # Even though mocks are required, the primary purpose of these tests is to
      # test if the promise and callback API is working as expected
      describe 'promise API', ->
        @beforeAll prepare ->
          path.getDisplayName()

        it 'should be a nice human readable string', eventually (name) ->
          name.should.equal "Employee > Years Alive"
          return undefined

      describe 'callback api', ->
        it 'should yield the name', (done) ->
          path.getDisplayName (err, name) ->
            if err?
              done err
              return
            else
              try
                name.should.equal "Employee > Years Alive"
                done()
              catch e
                done e
            return
          return undefined

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

  unitTests() && describe 'Simple reference', ->
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

  unitTests() && describe 'Simple collection', ->
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

  unitTests() && describe 'Subclassed path', ->
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

  unitTests() && describe 'A path with a custom name', ->
    path = testmodel.makePath 'Company.departments.manager.address'
    path.displayName = "FOO"

    describe '#getDisplayName', ->

      @afterEach PathInfo.flushCache

      it 'should promise to return the name we gave it', (done) ->
        path.getDisplayName (err, name) ->
          name.should.equal "FOO"
        done()
        return undefined

  bothTests() && describe 'Long reference with collection chain', ->

    PathInfo.flushCache()

    path = testmodel.makePath 'Company.departments.manager.address'

    it 'should stringify with toString()', ->
      path.toString().should.equal('Company.departments.manager.address')
    it 'should stringify with toPathString()', ->
      path.toPathString().should.equal('Company.departments.manager.address')
    it 'should stringify with string concatenation', ->
      ('' + path).should.equal('Company.departments.manager.address')

    integrationTests() && describe '#getPathInfo', ->
      @beforeAll prepare ->
        path.getDisplayName()

      it 'should promise to return a name', eventually (name) ->
        name.should.equal "Company > Departments > Manager > Address"

    unitTests() && describe '#getType()', -> it 'should report an appropriate type', ->
      path.getType().name.should.equal('Address')

    unitTests() && describe '#containsCollection()', -> it 'should contain a collection', ->
      path.containsCollection().should.be.true

    unitTests() && describe '#getParent()', -> it 'should have a parent of the right type', ->
      path.getParent().getType().name.should.equal('Manager')

    unitTests() && describe '#append(field)', ->
      
      it 'should return the appropriate child path', ->
        path.append('id').getType().should.equal('Integer')

      it "should throw if the field doesn't exist", ->
        (-> path.append 'postCode').should.throw()

    unitTests() && describe '#isRoot()', -> it 'should return false', ->
      path.isRoot().should.be.false

    unitTests() && describe '#isAttribute()', -> it 'should return false', ->
      path.isAttribute().should.be.false

    unitTests() && describe '#isReference', -> it 'should return true', ->
      path.isReference().should.be.true

    unitTests() && describe '#isCollection', -> it 'should return false', ->
      path.isCollection().should.not.be.true

    unitTests() && describe '#isClass', -> it 'should return true', ->
      path.isClass().should.be.true

    unitTests() && describe '#isa(type)', ->
      it 'should not say it is an Employee', -> path.isa('Employee').should.not.be.true

      it 'should say it is a Thing', -> path.isa('Thing').should.be.true

      it 'should not say it is a Department', -> path.isa('Department').should.not.be.true

      it 'should not say it is an int', -> path.isa('int').should.not.be.true

bothTests() && describe 'Two similar paths', ->

  pathA = testmodel.makePath 'Employee.name'
  pathB = testmodel.makePath 'Employee.name'

  unitTests() && it 'should equal each other', ->
    pathA.equals(pathB).should.be.true

  integrationTests() && describe 'their names', ->

    @beforeAll prepare ->
      Fixture.utils.parallel(p.getDisplayName() for p in [pathA, pathB])

    it 'should be the same', eventually ([a, b]) ->
      a.should.eql b

describe 'The path of a poor person', ->

  path = testmodel.makePath 'Broke'

  @beforeAll prepare ->
    path.getDisplayName()

  it 'should say this person is poor', eventually (name) ->
    name.should.eql 'Poor Person'

describe 'The path of a simple object', ->

  path = testmodel.makePath 'SimpleObject'

  it 'should say that this path is not an IMO', ->
    path.isa('InterMineObject').should.be.false

  it 'should say that this path is a JLO', ->
    path.isa('java.lang.Object').should.be.true

describe 'PathInfo::isReverseReference', ->

  root_path = testmodel.makePath 'Employee'
  # Straight ref.
  sr_path = testmodel.makePath 'Employee.department.company'
  a_path = testmodel.makePath 'Employee.department.name'
  rr_path_0 = testmodel.makePath 'Employee.department.employees'
  rr_path_1 = testmodel.makePath 'Employee.department.company.departments'
  rr_path_2 = testmodel.makePath 'Company.departments.company'
  inner_rev_ref = testmodel.makePath 'Employee.department.employees.address'

  it 'should say that Employee is not a reverse reference', ->
    root_path.isReverseReference().should.not.be.true

  it 'should say that Employee.department.company is not a reverse reference', ->
    sr_path.isReverseReference().should.not.be.true

  it 'should say that Employee.department.name is not a reverse reference', ->
    a_path.isReverseReference().should.not.be.true

  it 'should say that Employee.department.employees.address is not a reverse reference', ->
    inner_rev_ref.isReverseReference().should.not.be.true

  it 'should say that Employee.department.employees is a reverse reference', ->
    rr_path_0.isReverseReference().should.be.true

  it 'should say that Employee.department.company.departments is a reverse reference', ->
    rr_path_1.isReverseReference().should.be.true

  it 'should say that Company.departments.company is a reverse reference', ->
    rr_path_2.isReverseReference().should.be.true


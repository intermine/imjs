Fixture = require './lib/fixture'
should = require 'should'
{TESTMODEL} = require './data/model'
{Query, Model, utils: {any}} = Fixture

describe 'Query#getPossiblePaths', ->

  describe 'The possible paths of a query rooted at Company, default depth', ->

    model = Model.load TESTMODEL.model
    query = new Query {model, root: 'Company'}

    paths = query.getPossiblePaths()

    it 'should be an array of strings', ->
      paths.should.be.an.Array
      for path in paths
        path.should.be.a.String

    it 'should only include valid paths', ->
      for path in paths
        should.exist query.makePath(path).getType

    it 'should include Company.department.employees.name', ->
      paths.should.include 'Company.departments.employees.name'

    it 'should include Company.oldContracts.companys.address', ->
      paths.should.include 'Company.oldContracts.companys.address'

    it 'should not include very deep paths', ->
      paths.should.not.include 'Company.departments.manager.department.employees.address.address'

  describe 'The possible paths of a query rooted at Company, extra deep', ->

    model = Model.load TESTMODEL.model
    query = new Query {model, root: 'Company'}

    paths = query.getPossiblePaths( 6 )

    it 'should include very deep paths', ->
      paths.should.include 'Company.departments.manager.department.employees.address.address'

    it 'should not include silly paths', ->
      paths.should.not.include 'Company.foo.bar.quux'

describe 'Query#canHaveMultipleValues', ->

  describe 'A path that cannot have multiple values', ->

    model = Model.load TESTMODEL.model
    query = new Query {model, root: 'Employee'}

    path = 'department.company.name'

    it 'should not be able to have multiple values', ->
      query.canHaveMultipleValues(path).should.not.be.true

  describe 'A path that can have multiple values', ->

    model = Model.load TESTMODEL.model
    query = new Query {model, root: 'Company'}

    path = 'departments.employees.name'

    it 'should be able to have multiple values', ->
      query.canHaveMultipleValues(path).should.be.true

describe 'Query#getQueryNodes', ->

  describe 'The nodes of a query', ->

    model = Model.load TESTMODEL.model
    root = 'Employee'
    select = ['name', 'department.name']
    where = {'address.address': 'foo', 'department.manager': {in: 'bad-manager-list'}}
    query = new Query {model, root, select, where}
    includesPath = (xs, path) -> any xs, (x) -> String(x) is path

    queryNodes = query.getQueryNodes()

    it 'should be an array', ->
      queryNodes.should.be.an.Array

    it 'should be an array of PathInfo instances', ->
      for n in queryNodes
        should.exist n.getType

    it 'should not include any attributes', ->
      for n in queryNodes
        n.isAttribute().should.not.be.true

    it 'should include the nodes in the view', ->
      for path in ['Employee', 'Employee.department']
        includesPath(queryNodes, path).should.be.true

    it 'should include the nodes in the constraints', ->
      for path in ['Employee.address', 'Employee.department.manager']
        includesPath(queryNodes, path).should.be.true

    it 'should not include nodes not in the query', ->
      includesPath(queryNodes, 'Employee.department.company').should.not.be.true

describe 'Query#isOuterJoin', ->

  model = Model.load TESTMODEL.model
  root = 'Employee'
  select = ['name', 'department.name']
  where = {'address.address': 'foo', 'department.manager': {in: 'bad-manager-list'}}
  joins = ['address']
  query = new Query {model, root, select, where, joins}

  describe 'An outer-joined path', ->

    path = 'Employee.address'

    it 'should be considered to be outer joined', ->
      query.isOuterJoin(path).should.be.true

  describe 'A non-outer joined path', ->

    path = 'Employee.department'

    it 'should not be considered to be outer joined', ->
      query.isOuterJoin(path).should.not.be.true

  describe 'attempting to get information about a nonsense path', ->
    
    attempt = -> query.isOuterJoin 'foo'

    it 'should throw an error', ->
      attempt.should.not.throwError()

    it 'should however return false', ->
      attempt().should.not.be.true


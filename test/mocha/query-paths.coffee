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

describe 'Query#getSortDirection', ->

  model = Model.load TESTMODEL.model
  root = 'Employee'
  select = ['name', 'department.name']
  sortOrder = [['age', 'DESC'], ['name', 'ASC']]
  where = {'address.address': 'foo', 'department.manager': {in: 'bad-manager-list'}}
  joins = ['address']
  query = new Query {model, root, select, where, joins, sortOrder}

  describe 'direction of "age"', ->

    direction = query.getSortDirection 'Employee.age'

    it 'should be "DESC"', ->
      direction.should.equal "DESC"

  describe 'direction of "name"', ->

    direction = query.getSortDirection 'Employee.name'

    it 'should be "ASC"', ->
      direction.should.equal "ASC"

  describe 'direction of "age", short path', ->

    direction = query.getSortDirection 'age'

    it 'should be "DESC"', ->
      direction.should.equal "DESC"

  describe 'direction of "name", short path', ->

    direction = query.getSortDirection 'name'

    it 'should be "ASC"', ->
      direction.should.equal "ASC"

  describe 'the direction of "address.address"', ->
    
    direction = query.getSortDirection 'Employee.address.address'

    it 'should not exist', ->
      should.not.exist direction

  describe 'Attempting to get the direction of nonsense', ->

    attempt = -> query.getSortDirection 'Foo.bar'

    it 'should throw a helpful error', ->
      attempt.should.throwError /Foo.bar/

  describe 'Attempting to get the direction of irrelevant path', ->

    attempt = -> query.getSortDirection 'Employee.department.company.name'

    it 'should throw a helpful error', ->
      attempt.should.throwError /not in the query/

describe 'Query#addOrSetSortOrder', ->

  model = Model.load TESTMODEL.model
  root = 'Employee'
  select = ['name', 'department.name']
  sortOrder = [['age', 'DESC'], ['name', 'ASC']]
  where = {'address.address': 'foo', 'department.manager': {in: 'bad-manager-list'}}
  joins = ['address']
  query = new Query {model, root, select, where, joins, sortOrder}

  describe 'change direction of "age"', ->

    query.addOrSetSortOrder ['age', 'ASC']
    direction = query.getSortDirection 'Employee.age'

    it 'should have toggled the sort order', ->
      direction.should.equal 'ASC'

  describe 'change direction of "name"', ->

    query.addOrSetSortOrder ['name', 'DESC']
    direction = query.getSortDirection 'Employee.name'

    it 'should have toggled the sort order', ->
      direction.should.equal 'DESC'

  describe 'add direction for address.address', ->

    query.addOrSetSortOrder ['address.address', 'DESC']
    direction = query.getSortDirection 'Employee.address.address'

    it 'should have set the sort order', ->
      direction.should.equal 'DESC'

describe 'Query#setJoinStyle', ->

  model = Model.load TESTMODEL.model
  root = 'Employee'
  select = ['name', 'department.name']
  where = {'address.address': 'foo', 'department.manager': {in: 'bad-manager-list'}}

  describe 'setting the default join style', ->
    query = new Query {model, root, select, where}
    query.setJoinStyle 'address'
    styleOfAddress = query.joins['Employee.address']

    it 'should now be an outer join', ->
      styleOfAddress.should.equal 'OUTER'

  describe 'attempting to add an invalid join style', ->
    query = new Query {model, root, select, where}
    attempt = -> query.setJoinStyle 'address', 'FUNKY'

    it 'should throw a helpful error message', ->
      attempt.should.throwError /Invalid join style/

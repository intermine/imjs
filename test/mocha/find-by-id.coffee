Fixture = require './lib/fixture'
{report, eventually, prepare} = require './lib/utils'
{defer, get} = Fixture.funcutils
{integrationTests} = require './lib/segregation'

caar = (xs) -> xs[0][0]

findEmployee = (service, q) ->
  service.rows(q).then(caar).then (id) -> service.findById 'Employee', id

findFieldsOfEmployee = (service, q, fields) ->
  service.rows(q).then(caar).then (id) -> service.findById 'Employee', id, fields

# We have to query each time as ids are volatile.
DAVIDS_ID_Q = select: ['Employee.id'], where: {name: 'David Brent'}

integrationTests() && describe 'lookup', ->

  {service} = new Fixture()

  describe 'Looking for David', ->

    describe 'using the promises API', ->

      @beforeAll prepare ->
        service.lookup 'Employee', 'David Brent'

      it 'should find someone with the right name', eventually ([david]) ->
        david.name.should.equal 'David Brent'

      it 'should find someone in the right department', eventually ([david]) ->
        david.department.name.should.equal 'Sales'

      it 'should find someone 41 years of age', eventually ([david]) ->
        david.age.should.equal 41

      it 'should find a full-time worker', eventually ([david]) ->
        david.fullTime.should.be.false

      it 'should find a manager', eventually ([david]) ->
        david['class'].should.equal 'Manager'

    describe 'using the call-back API', ->

      it 'should find someone with the right name and age.', (done) ->
        service.lookup 'Employee', 'David Brent', (err, found) ->
          done err if err?
          try
            [david] = found
            david.name.should.equal 'David Brent'
            david.age.should.equal 41
            done()
          catch e
            done new Error e
        return undefined

integrationTests() && describe 'find', ->

  {service} = new Fixture()

  describe 'Looking for David', ->

    describe 'using the promises API', ->

      @beforeAll prepare ->
        service.find 'Employee', 'David Brent'

      it 'should find someone with the right name', eventually (david) ->
        david.name.should.equal 'David Brent'

      it 'should find someone in the right department', eventually (david) ->
        david.department.name.should.equal 'Sales'

      it 'should find someone 41 years of age', eventually (david) ->
        david.age.should.equal 41

      it 'should find a full-time worker', eventually (david) ->
        david.fullTime.should.be.false

      it 'should find a manager', eventually (david) ->
        david['class'].should.equal 'Manager'

    describe 'using the call-back API', ->

      it 'should find someone with the right name and age.', (done) ->
        service.find 'Employee', 'David Brent', (err, david) ->
          done err if err?
          try
            david.name.should.equal 'David Brent'
            david.age.should.equal 41
            done()
          catch e
            done new Error e
        return undefined

# Same function as above called, tests if the service finds by id correctly
integrationTests() && describe 'Service#findById', ->

  {service} = new Fixture()

  describe 'Looking for David', ->

    q = DAVIDS_ID_Q

    describe 'using the promises API', ->

      @beforeAll (done) -> report done, @promise = findEmployee service, q

      it 'should find someone with the right name', eventually (david) ->
        david.name.should.equal 'David Brent'

      it 'should find someone in the right department', eventually (david) ->
        david.department.name.should.equal 'Sales'

      it 'should find someone 41 years of age', eventually (david) ->
        david.age.should.equal 41

      it 'should find a full-time worker', eventually (david) ->
        david.fullTime.should.be.false

      it 'should find a manager', eventually (david) ->
        david['class'].should.equal 'Manager'

    describe 'specific fields', ->

      q = DAVIDS_ID_Q
      flds = ['name', 'end']

      @beforeAll (done) ->
        report done, @promise = findFieldsOfEmployee service, q, flds

      it 'should find someone with the right name', eventually (david) ->
        david.name.should.equal 'David Brent'

      it 'should not return a department', eventually (david) ->
        david.should.not.have.property 'department'

      it 'should not have an age', eventually (david) ->
        david.should.not.have.property 'age'

      it 'should have a title', eventually (david) ->
        david.should.have.property 'end'

      it 'should find a manager', eventually (david) ->
        david['class'].should.equal 'Manager'

    describe 'using the call-back API', ->

      @beforeAll (done) -> report done, @promise = service.rows(q).then (rows) -> rows[0][0]

      it 'should find someone with the right name and age.', eventually (id) ->
        {promise, resolve, reject} = defer()
        service.findById 'Employee', id, (err, david) ->
          reject err if err?
          try
            david.name.should.equal 'David Brent'
            david.age.should.equal 41
            resolve()
          catch e
            reject new Error e
        return promise
  
  describe 'Looking for B1', ->

    q = select: ['Employee.id'], where: {name: 'EmployeeB1'}
    
    @beforeAll (done) -> report done, @promise = findEmployee service, q

    it 'should find someone with the right name', eventually (david) ->
      david.name.should.equal 'EmployeeB1'

    it 'should find someone in the right department', eventually (david) ->
      david.department.name.should.equal 'DepartmentB1'

    it 'should find someone 40 years of age', eventually (david) ->
      david.age.should.equal 40

    it 'should find a full-time worker', eventually (david) ->
      david.fullTime.should.be.true

    it 'should find a manager', eventually (david) ->
      david['class'].should.equal 'CEO'


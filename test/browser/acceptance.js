describe('Acceptance', function() {

  var invoke = function(name) { return function(obj) { return obj[name](); } };
  var Service = intermine.Service;
  var args = {
    root: "bc:8081/intermine-test",
    token: "test-user-token"
  };

  describe('Instantiate service', function() {
    it('Should be able to create a service', function() {
      should.exist(new Service(args));
    });

  });

  describe('Static Resources', function() {

    var service = new Service(args);

    it('Should be able to get a sensible version', function(done) {
      service.fetchVersion().fail(done).done(function(v) {
        v.should.be.above(8);
        done();
      });
    });

  });

  describe('Data Requests', function() {

    var service = new Service(args);

    it('Should be able to count the employees', function(done) {
      service.count({select: ['id'], from: 'Employee'}).fail(done).done(function(c) {
        c.should.eql(132);
        done();
      });
    });

    it('Should find lists with brenda in them', function(done) {
      var onDone = function(lists) {
        lists.length.should.eql(2);
        done();
      };
      service.fetchListsContaining({type: 'Employee', publicId: 'Brenda'})
                       .then(onDone, done);
    });

    it('Should find the ages of the 46 employees over 50 add up to 2688', function(done) {
      var oldies = {select: ['Employee.age'], where: { age: {gt: 50} }};
      var test = function(rows) {
        rows.length.should.equal(46);
        rows.reduce(function(acc, row) { return acc + row[0] }, 0).should.eql(2688);
        done();
      };
      service.query(oldies).then(invoke('rows')).then(test, done);
    });

  });
});
